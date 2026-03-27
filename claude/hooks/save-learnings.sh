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

# ── Extract learning signals ───────────────────────────────────────────────
# 1. Warning / important patterns in assistant text (lines with actionable info)
WARNINGS=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(注意|重要|必ず|NG|禁止|避ける|罠|落とし穴|原因は|根本原因|理由は|ポイントは|コツは|⚠️|🚨|🔴|エラーの原因|注意点|気をつける|注意が必要)' | \
  awk 'length > 15 && length < 250' | \
  sed 's/^[[:space:]]*//' | \
  sed 's/\*\*//g' | \
  head -3)

# 2. User corrections (user flagged something was wrong)
CORRECTIONS=$(echo "$USER_TEXT" | \
  grep -E '(違う|NG|じゃなく|でなく|やり直し|ダメ|だめ|間違|直して|修正して|そうじゃない|異なる)' | \
  awk 'length > 5 && length < 150' | \
  head -2)

# 3. Session task summary: first meaningful user request
FIRST_REQUEST=$(echo "$USER_TEXT" | \
  grep -v '^$' | grep -v '^\[' | \
  awk 'length > 8' | head -1 | cut -c1-120)

# 4. Completion/result line from assistant
COMPLETION=$(echo "$ASSISTANT_TEXT" | \
  grep -E '(変更:|コミット:|作成しました|更新しました|修正しました|追加しました|完了しました|対応しました)' | \
  tail -1 | cut -c1-150)

# ── Build output lines ────────────────────────────────────────────────────
LINES=()

while IFS= read -r line; do
  [[ -n "$line" ]] && LINES+=("- $line")
done <<< "$WARNINGS"

while IFS= read -r line; do
  [[ -n "$line" ]] && LINES+=("- [ユーザー修正] $line")
done <<< "$CORRECTIONS"

# If still empty, write minimal task summary
if [ "${#LINES[@]}" -eq 0 ]; then
  [[ -n "$FIRST_REQUEST" ]] && LINES+=("- 作業: $FIRST_REQUEST")
  [[ -n "$COMPLETION" ]]    && LINES+=("- 完了: $COMPLETION")
fi

[ "${#LINES[@]}" -eq 0 ] && exit 0

# ── Write to domain file ───────────────────────────────────────────────────
DOMAIN_FILE="$LEARNINGS_DIR/${DOMAIN}.md"
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
