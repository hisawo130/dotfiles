#!/bin/bash
# save-learnings.sh
# Claude Code Stop hook: extract session learnings and save by domain.
# Rule-based extraction (no claude -p dependency).

# Recursion guard
[ "${CLAUDE_LEARNING_EXTRACT:-}" = "1" ] && exit 0

# ── Config ────────────────────────────────────────────────────────────────
LEARNINGS_DIR="$HOME/.claude/learnings"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
CWD=$(pwd)
DIR=$(basename "$CWD")

# ── Early exit: skip dirs that would produce CLAUDE.md / system noise ────
# Home dir, dotfiles, and .claude itself all contain instruction text that
# matches keyword patterns but have zero learning value.
if [ "$CWD" = "$HOME" ] || \
   [ "$CWD" = "$HOME/dotfiles" ] || \
   [[ "$CWD" == "$HOME/.claude"* ]] || \
   [[ "$CWD" == "$HOME/dotfiles/claude"* ]]; then
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
[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

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
  if type == "string" and (length > 5) then . else "" end
' "$TRANSCRIPT" 2>/dev/null)

# Skip trivial sessions
TOTAL_LEN=$(( ${#ASSISTANT_TEXT} + ${#USER_TEXT} ))
[ "$TOTAL_LEN" -lt 200 ] && exit 0

# ── Noise filter function ─────────────────────────────────────────────────
# Removes lines that are structural/template content, not real learnings:
#   - markdown table rows (|...|...|)
#   - numbered list items from CLAUDE.md docs (1. 2. 3. with long content)
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
# Adds a type prefix based on content classification.
tag_line() {
  local line="$1"
  if echo "$line" | grep -qE '(罠|落とし穴|バグ|失敗|NG|禁止|エラーの原因|回避すべき|してはいけない)'; then
    echo "[gotcha] $line"
  elif echo "$line" | grep -qE '(未解決|要調査|継続調査|TODO|open:)'; then
    echo "[open] $line"
  elif echo "$line" | grep -qE '(解決方法|正しい方法|うまくいく|成功した|このやり方|このアプローチ)'; then
    echo "[pattern] $line"
  elif echo "$line" | grep -qE '(コツ|ポイントは|覚え書き|ベストプラクティス)'; then
    echo "[tip] $line"
  else
    echo "$line"
  fi
}

# ── Dedup check ───────────────────────────────────────────────────────────
# Returns 0 (true) if a line is already present in the recent domain file.
is_duplicate() {
  local line="$1"
  local file="$2"
  local key="${line:0:60}"
  [ -f "$file" ] && tail -200 "$file" | grep -qF "$key"
}

# ── Detect domain from project structure ──────────────────────────────────
DOMAIN="general"
if [ -f "$CWD/shopify.theme.toml" ] || [ -f "$CWD/config/settings_schema.json" ]; then
  DOMAIN="shopify"
elif [ -d "$CWD/ec_force" ] || [ -d "$CWD/layouts/ec_force" ]; then
  DOMAIN="ecforce"
elif [ -f "$CWD/wp-config.php" ] || [ -d "$CWD/wp-content" ]; then
  DOMAIN="wordpress"
elif [ -f "$CWD/package.json" ] && grep -q '"@shopify/hydrogen' "$CWD/package.json" 2>/dev/null; then
  DOMAIN="shopify-hydrogen"
elif [ -f "$CWD/package.json" ] && grep -q '"@shopify/' "$CWD/package.json" 2>/dev/null; then
  DOMAIN="shopify-app"
elif [ -f "$CWD/package.json" ] && grep -q '"next"' "$CWD/package.json" 2>/dev/null; then
  DOMAIN="react-nextjs"
elif [ -f "$CWD/package.json" ] && grep -q '"nuxt"' "$CWD/package.json" 2>/dev/null; then
  DOMAIN="vue-nuxt"
elif [ -f "$CWD/wrangler.toml" ] || [ -f "$CWD/wrangler.jsonc" ]; then
  DOMAIN="cloudflare"
elif [ -d "$CWD/.github/workflows" ]; then
  DOMAIN="github-actions"
elif [ -d "$CWD/app/Plugin" ] || [ -f "$CWD/app/config/eccube/config.yaml" ]; then
  DOMAIN="ec-cube"
fi

# Keyword-based domain override (for sessions in non-project dirs)
if [ "$DOMAIN" = "general" ]; then
  COMBINED_TEXT="$ASSISTANT_TEXT$USER_TEXT"
  if echo "$COMBINED_TEXT" | grep -qiE '(shopify|liquid.*section|dawn theme|{% schema %}|storefront api)'; then
    DOMAIN="shopify"
  elif echo "$COMBINED_TEXT" | grep -qiE '(ecforce|ec_force|file_root_path|\.html\.liquid)'; then
    DOMAIN="ecforce"
  elif echo "$COMBINED_TEXT" | grep -qiE '(google analytics|gtm|ga4|dataLayer|google tag)'; then
    DOMAIN="ga4-gtm"
  elif echo "$COMBINED_TEXT" | grep -qiE '(klaviyo|flow trigger|email segment)'; then
    DOMAIN="klaviyo"
  elif echo "$COMBINED_TEXT" | grep -qiE '(matrixify|shopify export|csv import|bulkimport)'; then
    DOMAIN="matrixify"
  elif echo "$COMBINED_TEXT" | grep -qiE '(github actions|workflow run|\.github/workflows)'; then
    DOMAIN="github-actions"
  elif echo "$COMBINED_TEXT" | grep -qiE '(cloudflare|wrangler|workers|pages deploy)'; then
    DOMAIN="cloudflare"
  elif echo "$COMBINED_TEXT" | grep -qiE '(make\.com|integromat|zapier|シナリオ|モジュール)'; then
    DOMAIN="make-zapier"
  fi
fi

DOMAIN_FILE="$LEARNINGS_DIR/${DOMAIN}.md"

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

# 3. User corrections (user flagged something was wrong)
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

# ── Build output lines (with dedup check) ─────────────────────────────────
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
    tagged="[correction] $line"
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

# ── Write to domain file ───────────────────────────────────────────────────
mkdir -p "$LEARNINGS_DIR"

if [ ! -f "$DOMAIN_FILE" ]; then
  TITLE=$(echo "$DOMAIN" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
  echo "# ${TITLE} Learnings" > "$DOMAIN_FILE"
fi

{
  echo ""
  echo "## $DATE $TIME | $DIR"
  printf '%s\n' "${LINES[@]}"
} >> "$DOMAIN_FILE"

# ── Sync to dotfiles ───────────────────────────────────────────────────────
DOTFILES="$HOME/dotfiles"
if git -C "$DOTFILES" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$DOTFILES" add "claude/learnings/${DOMAIN}.md" 2>/dev/null
  if ! git -C "$DOTFILES" diff --cached --quiet 2>/dev/null; then
    git -C "$DOTFILES" commit -m "docs: [${DOMAIN}] 学びログ追加 ($DATE $TIME | $DIR)" 2>/dev/null
    git -C "$DOTFILES" push 2>/dev/null || true
  fi
fi

exit 0
