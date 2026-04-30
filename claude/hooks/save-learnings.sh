#!/bin/bash
# save-learnings.sh
# Claude Code Stop hook: extract session learnings and save by domain.
# Rule-based extraction (no claude -p dependency).

# Recursion guard
[ "${CLAUDE_LEARNING_EXTRACT:-}" = "1" ] && exit 0

# ── Config ────────────────────────────────────────────────────────────────
LEARNINGS_DIR="$HOME/.claude/learnings"
LIB_DIR="$(dirname "$0")/lib"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
CWD=$(pwd)
DIR=$(basename "$CWD")

# Resolve dotfiles root (handles ≠ ~/dotfiles installs)
# shellcheck source=lib/dotfiles-root.sh
source "$LIB_DIR/dotfiles-root.sh" 2>/dev/null
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# ── Early exit: skip dirs that would produce CLAUDE.md / system noise ────
# Home dir, dotfiles, and .claude itself all contain instruction text that
# matches keyword patterns but have zero learning value.
if [ "$CWD" = "$HOME" ] || \
   [ "$CWD" = "$DOTFILES" ] || \
   [[ "$CWD" == "$HOME/.claude"* ]] || \
   [[ "$CWD" == "$DOTFILES/claude"* ]]; then
  exit 0
fi

# ── Read hook input ───────────────────────────────────────────────────────
HOOK_INPUT=$(cat /dev/stdin 2>/dev/null || true)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)
[ -z "$SESSION_ID" ] && exit 0

# ── Find transcript ────────────────────────────────────────────────────────
SANITIZED_CWD=$(echo "$CWD" | sed 's|/|-|g')
TRANSCRIPT="$HOME/.claude/projects/${SANITIZED_CWD}/${SESSION_ID}.jsonl"

if [ ! -f "$TRANSCRIPT" ]; then
  TRANSCRIPT=$(grep -rl "\"$SESSION_ID\"" "$HOME/.claude/projects" \
    --include="*.jsonl" -l 2>/dev/null | head -1 || true)
fi
{ [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; } && exit 0

# ── Extract text content ───────────────────────────────────────────────────
ASSISTANT_TEXT=$(jq -r '
  select(.type == "assistant") |
  (.message.content // []) |
  if type == "array" then
    map(select(.type == "text") | .text) | join("\n")
  else "" end
' "$TRANSCRIPT" 2>/dev/null)

USER_TEXT=$(jq -r '
  select(.type == "user") |
  (.message.content) |
  if type == "string" and (length > 5) then .
  elif type == "array" then
    map(select(.type == "text") | .text // "") | join("\n")
  else "" end
' "$TRANSCRIPT" 2>/dev/null)

# Skip trivial sessions
TOTAL_LEN=$(( ${#ASSISTANT_TEXT} + ${#USER_TEXT} ))
[ "$TOTAL_LEN" -lt 200 ] && exit 0

# ── Noise filter function ─────────────────────────────────────────────────
# Removes lines that are structural/template content, not real learnings:
#   - markdown table rows (|...|...|)
#   - numbered list items from CLAUDE.md docs referencing system internals
#   - lines referencing the learnings/hooks system itself
#   - lines with shell variable names (extracted from scripts)
filter_noise() {
  grep -v '|.*|.*|' | \
  grep -v '^\s*[0-9]\+\. .*\(LEARNINGS\|TRANSCRIPT\|SESSION\|WebFetch\|grep -E\|awk \)' | \
  grep -v 'LEARNINGS_DIR\|TRANSCRIPT\|SESSION_ID\|save-learnings\|claude/learnings' | \
  grep -v '^\s*```' | \
  grep -v 'Co-authored-by:\|Co-Authored-By:' | \
  grep -v '「残念ながら' | \
  grep -v '^\s*\$(' | \
  awk 'length > 15 && length < 280'
}

# ── Type tag function ─────────────────────────────────────────────────────
# Unified tagging for all learning types — including corrections.
tag_line() {
  local line="$1"
  if echo "$line" | grep -qiE '(罠|落とし穴|バグ|失敗|NG|禁止|エラーの原因|回避すべき|してはいけない|avoid|never use|broken|mistake|crash|don.t use|watch out|wrong way)'; then
    echo "[gotcha] $line"
  elif echo "$line" | grep -qiE '(違う|じゃなく|ではなく|でなく|やり直し|ダメ|だめ|間違|直して|修正して|そうじゃない|異なる|actually[, ]|instead[, ]|should be|not.*correct|incorrect)'; then
    echo "[correction] $line"
  elif echo "$line" | grep -qiE '(未解決|要調査|継続調査|TODO|FIXME|WIP|open:|pending|blocked)'; then
    echo "[open] $line"
  elif echo "$line" | grep -qiE '(解決方法|正しい方法|うまくいく|成功した|このやり方|このアプローチ|works by|solution is|the key is|turns out|resolved by)'; then
    echo "[pattern] $line"
  elif echo "$line" | grep -qiE '(コツ|ポイントは|覚え書き|ベストプラクティス|note that|remember[: ]|heads.?up|best practice|pro.?tip)'; then
    echo "[tip] $line"
  else
    echo "$line"
  fi
}

# ── Dedup check ───────────────────────────────────────────────────────────
# [gotcha] and [recurring] scan the full file; other tags use tail -200.
is_duplicate() {
  local line="$1"
  local file="$2"
  local key="${line:0:60}"
  [ ! -f "$file" ] && return 1
  if echo "$line" | grep -qE '\[(gotcha|recurring)\]'; then
    grep -qF "$key" "$file"
  else
    tail -200 "$file" | grep -qF "$key"
  fi
}

# ── Recurring pattern tracker ─────────────────────────────────────────────
# Promotes [gotcha] entries seen 3+ times to [recurring] in a summary section.
update_recurring() {
  local file="$1"
  local RECURRING_HDR="## Recurring Patterns"
  local date_now; date_now=$(date +%Y-%m-%d)

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local key="${entry:0:50}"
    local count; count=$(grep -cF "$key" "$file" 2>/dev/null || echo 0)
    if [ "$count" -ge 3 ]; then
      # Skip if already registered in Recurring section
      if grep '\[recurring\]' "$file" 2>/dev/null | grep -qF "$key"; then
        continue
      fi
      if grep -q "$RECURRING_HDR" "$file"; then
        _tmp=$(mktemp)
        sed "/$RECURRING_HDR/a - [recurring] ${key} — seen ${count} times" "$file" > "$_tmp" && mv "$_tmp" "$file"
      else
        printf '\n%s (updated %s)\n- [recurring] %s — seen %s times\n' \
          "$RECURRING_HDR" "$date_now" "$key" "$count" >> "$file"
      fi
    fi
  done < <(grep '\[gotcha\]' "$file" 2>/dev/null | sed 's/^- //' | sed 's/\[gotcha\] //')
}

# ── Detect domain via shared library ──────────────────────────────────────
DETECT_CWD="$CWD"
DETECT_TEXT="$ASSISTANT_TEXT$USER_TEXT"
# shellcheck source=lib/detect-domain.sh
source "$LIB_DIR/detect-domain.sh" 2>/dev/null || { PRIMARY_DOMAIN="general"; SECONDARY_DOMAINS=(); }

ALL_DOMAINS=("$PRIMARY_DOMAIN" "${SECONDARY_DOMAINS[@]}")
DOMAIN_FILE="$LEARNINGS_DIR/${PRIMARY_DOMAIN}.md"

# ── Extract learning signals ───────────────────────────────────────────────

# 1. Warning / gotcha patterns (罠・注意・NG)
WARNINGS=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(注意|重要|必ず|NG|禁止|避ける|罠|落とし穴|根本原因|理由は|ポイントは|コツは|⚠️|🚨|🔴|エラーの原因|注意点|気をつける|注意が必要|してはいけない)' | \
  filter_noise | \
  sed 's/^[[:space:]]*//' | \
  sed 's/\*\*//g' | \
  head -3)

# 2. "What worked" patterns (解決策・正しい方法)
WHAT_WORKED=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(解決しました|解決方法は|正しいやり方は|このアプローチ|成功した|うまくいく|ベストプラクティス)' | \
  filter_noise | \
  sed 's/^[[:space:]]*//' | \
  sed 's/\*\*//g' | \
  head -2)

# 3. User corrections (user flagged something was wrong) — now via unified tag_line
CORRECTIONS=$(echo "$USER_TEXT" | \
  grep -E '(違う|NG|じゃなく|でなく|やり直し|ダメ|だめ|間違|直して|修正して|そうじゃない|異なる)' | \
  awk 'length > 5 && length < 150' | \
  head -2)

# 4. Unresolved issues
OPEN_ISSUES=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(未解決|要調査|継続調査|要確認|要検討|TODO:)' | \
  filter_noise | \
  sed 's/^[[:space:]]*//' | \
  sed 's/\*\*//g' | \
  head -2)

# 5. Session task summary (fallback)
FIRST_REQUEST=$(echo "$USER_TEXT" | \
  grep -v '^$' | grep -v '^\[' | \
  awk 'length > 8' | head -1 | cut -c1-120)

COMPLETION=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(変更:|コミット:|作成しました|更新しました|修正しました|追加しました|完了しました|対応しました)' | \
  tail -1 | cut -c1-150)

# ── Build output lines (with dedup check against primary domain file) ─────
LINES=()

while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    tagged=$(tag_line "$line")
    if ! is_duplicate "$tagged" "$DOMAIN_FILE"; then
      LINES+=("- $tagged")
    fi
  fi
done <<< "$WARNINGS"

while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    tagged="[pattern] $line"
    if ! is_duplicate "$tagged" "$DOMAIN_FILE"; then
      LINES+=("- $tagged")
    fi
  fi
done <<< "$WHAT_WORKED"

while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    tagged=$(tag_line "$line")   # unified — may produce [correction] or plain
    if ! is_duplicate "$tagged" "$DOMAIN_FILE"; then
      LINES+=("- $tagged")
    fi
  fi
done <<< "$CORRECTIONS"

while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    tagged="[open] $line"
    if ! is_duplicate "$tagged" "$DOMAIN_FILE"; then
      LINES+=("- $tagged")
    fi
  fi
done <<< "$OPEN_ISSUES"

# Fallback: minimal task summary if nothing substantive was extracted
if [ "${#LINES[@]}" -eq 0 ]; then
  [[ -n "$FIRST_REQUEST" ]] && LINES+=("- 作業: $FIRST_REQUEST")
  [[ -n "$COMPLETION" ]] && LINES+=("- 完了: $COMPLETION")
fi

[ "${#LINES[@]}" -eq 0 ] && exit 0

# ── Write to all detected domain files ────────────────────────────────────
mkdir -p "$LEARNINGS_DIR"

for domain in "${ALL_DOMAINS[@]}"; do
  [ -z "$domain" ] && continue
  local_file="$LEARNINGS_DIR/${domain}.md"

  if [ ! -f "$local_file" ]; then
    title=$(echo "$domain" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    echo "# ${title} Learnings" > "$local_file"
  fi

  {
    echo ""
    echo "## $DATE $TIME | $DIR"
    printf '%s\n' "${LINES[@]}"
  } >> "$local_file"

  update_recurring "$local_file"
done

# ── Commit to dotfiles (push handled by session-end-notify.sh) ────────────
if git -C "$DOTFILES" rev-parse --is-inside-work-tree &>/dev/null; then
  for domain in "${ALL_DOMAINS[@]}"; do
    [ -z "$domain" ] && continue
    git -C "$DOTFILES" add "claude/learnings/${domain}.md" 2>/dev/null
  done
  if ! git -C "$DOTFILES" diff --cached --quiet 2>/dev/null; then
    git -C "$DOTFILES" commit \
      -m "docs: [${PRIMARY_DOMAIN}] 学びログ追加 ($DATE $TIME | $DIR)" 2>/dev/null
  fi
fi

exit 0
