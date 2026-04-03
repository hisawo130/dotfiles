#!/bin/bash
# ai-capture.sh
# Stop hook: AI-powered learning extraction using claude -p (haiku).
# Runs after save-learnings.sh as a higher-quality complement.
# Outputs are marked [ai] to distinguish from rule-based entries.

# Recursion guard — set as env var before spawning claude -p
[ "${CLAUDE_AI_CAPTURE:-}" = "1" ] && exit 0

# ── Config ─────────────────────────────────────────────────────────────────
LEARNINGS_DIR="$HOME/.claude/learnings"
LIB_DIR="$(dirname "$0")/lib"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
CWD=$(pwd)
DIR=$(basename "$CWD")

# Skip system dirs (same rule as save-learnings.sh)
if [[ "$CWD" == "$HOME/.claude"* ]] || \
   [[ "$CWD" == "$HOME/dotfiles/claude"* ]]; then
  exit 0
fi

# ── Read hook input ────────────────────────────────────────────────────────
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

# ── Extract text (capped to keep tokens low) ───────────────────────────────
ASSISTANT_TEXT=$(jq -r '
  select(.type == "assistant") |
  (.message.content // []) |
  if type == "array" then map(select(.type == "text") | .text) | join("\n") else "" end
' "$TRANSCRIPT" 2>/dev/null | head -c 8000)

USER_TEXT=$(jq -r '
  select(.type == "user") |
  (.message.content) |
  if type == "string" then .
  elif type == "array" then map(select(.type == "text") | .text // "") | join("\n")
  else "" end
' "$TRANSCRIPT" 2>/dev/null | head -c 2000)

TOTAL_LEN=$(( ${#ASSISTANT_TEXT} + ${#USER_TEXT} ))
[ "$TOTAL_LEN" -lt 300 ] && exit 0

# ── Detect domain ──────────────────────────────────────────────────────────
DETECT_CWD="$CWD"
DETECT_TEXT="$ASSISTANT_TEXT$USER_TEXT"
# shellcheck source=lib/detect-domain.sh
source "$LIB_DIR/detect-domain.sh" 2>/dev/null || { PRIMARY_DOMAIN="general"; SECONDARY_DOMAINS=(); }

DOMAIN_FILE="$LEARNINGS_DIR/${PRIMARY_DOMAIN}.md"

# ── Build prompt ───────────────────────────────────────────────────────────
PROMPT="学習ログ抽出システムです。以下のClaude Codeセッションから、将来同様の問題で悩んだ時に役立つ学びを抽出してください。

ドメイン: ${PRIMARY_DOMAIN} | プロジェクト: ${DIR}

## ユーザー発言
${USER_TEXT}

## アシスタント発言
${ASSISTANT_TEXT}

---
抽出ルール（厳守）:
- 再利用価値がある学びのみ。なければ空出力。
- 最大3件。1件も無理に作らない。
- タグ: [gotcha]=罠・NG・避けるべき, [pattern]=うまくいった方法, [correction]=ユーザーが誤りを指摘, [tip]=コツ・ポイント
- 形式: - [タグ] 内容（日本語、1行、150字以内）
- リストのみ出力。説明・前置き不要。"

# ── Call claude -p (haiku, minimal tokens) ────────────────────────────────
RESULT=$(CLAUDE_AI_CAPTURE=1 claude \
  --model claude-haiku-4-5-20251001 \
  -p "$PROMPT" \
  2>/dev/null | grep '^- \[' | head -3)

[ -z "$RESULT" ] && exit 0

# ── Dedup against existing file ────────────────────────────────────────────
is_dup() {
  local line="$1"
  local key="${line:0:80}"
  [ ! -f "$DOMAIN_FILE" ] && return 1
  grep -qF "$key" "$DOMAIN_FILE"
}

NEW_LINES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! is_dup "$line"; then
    NEW_LINES+=("$line")
  fi
done <<< "$RESULT"

[ "${#NEW_LINES[@]}" -eq 0 ] && exit 0

# ── Write to domain file ───────────────────────────────────────────────────
mkdir -p "$LEARNINGS_DIR"
if [ ! -f "$DOMAIN_FILE" ]; then
  title=$(echo "$PRIMARY_DOMAIN" | sed 's/-/ /g' | \
    awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
  echo "# ${title} Learnings" > "$DOMAIN_FILE"
fi

{
  echo ""
  echo "## $DATE $TIME | $DIR [ai]"
  printf '%s\n' "${NEW_LINES[@]}"
} >> "$DOMAIN_FILE"

# ── Commit to dotfiles ─────────────────────────────────────────────────────
DOTFILES="$HOME/dotfiles"
if git -C "$DOTFILES" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$DOTFILES" add "claude/learnings/${PRIMARY_DOMAIN}.md" 2>/dev/null
  if ! git -C "$DOTFILES" diff --cached --quiet 2>/dev/null; then
    git -C "$DOTFILES" commit \
      -m "docs: [${PRIMARY_DOMAIN}] AI学び抽出 ($DATE $TIME | $DIR)" 2>/dev/null
  fi
fi

exit 0
