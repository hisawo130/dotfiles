#!/bin/bash
# save-learnings.sh
# Claude Code Stop hook: extract session learnings and save globally.
# Triggered on session close. Reads transcript, calls claude -p to distill
# non-obvious learnings, appends to ~/.claude/learnings/YYYY-MM-DD.md.

# Recursion guard: this script itself spawns claude -p; prevent re-entry
[ "${CLAUDE_LEARNING_EXTRACT:-}" = "1" ] && exit 0

# ── Config ────────────────────────────────────────────────────────────────
LEARNINGS_DIR="$HOME/.claude/learnings"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
CWD=$(pwd)
DIR=$(basename "$CWD")
LEARNINGS_FILE="$LEARNINGS_DIR/$DATE.md"
MAX_TRANSCRIPT_CHARS=6000  # context sent to claude -p

# ── Read hook input from stdin ────────────────────────────────────────────
HOOK_INPUT=$(cat /dev/stdin 2>/dev/null || true)
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)

[ -z "$SESSION_ID" ] && exit 0

# ── Find transcript ────────────────────────────────────────────────────────
# Claude Code stores transcripts at:
#   ~/.claude/projects/<sanitized-cwd>/<session_id>.jsonl
# Sanitize: replace / with -
SANITIZED_CWD=$(echo "$CWD" | sed 's|/|-|g')
TRANSCRIPT="$HOME/.claude/projects/${SANITIZED_CWD}/${SESSION_ID}.jsonl"

if [ ! -f "$TRANSCRIPT" ]; then
  # Fallback: search by session_id
  TRANSCRIPT=$(grep -rl "\"$SESSION_ID\"" "$HOME/.claude/projects" \
    --include="*.jsonl" -l 2>/dev/null | head -1 || true)
fi

[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

# ── Extract text content from transcript ──────────────────────────────────
# Format: JSONL, each line has .type (assistant/user), .message.content[]
CONTEXT=$(jq -r '
  select(.type == "user" or .type == "assistant") |
  "[" + .type + "] " +
  (
    .message.content // [] |
    if type == "array" then
      map(select(.type == "text") | .text) | join(" ")
    elif type == "string" then .
    else ""
    end
  )
' "$TRANSCRIPT" 2>/dev/null | \
  grep -v '^\[user\] \[' | \
  grep -v '^\[assistant\] $' | \
  tail -c "$MAX_TRANSCRIPT_CHARS" || true)

[ -z "$CONTEXT" ] && exit 0

# ── Extract learnings via claude -p ───────────────────────────────────────
PROMPT="以下はClaudeセッションの会話ログ（末尾${MAX_TRANSCRIPT_CHARS}文字）です。

【抽出ルール】
- 具体的・非自明な学びのみ（プラットフォーム固有の罠、発見したバグの根本原因、有効だったパターン、ユーザーが修正した誤り）
- 最大3つ、日本語箇条書き（- で始める）
- 汎用アドバイス・自明な内容・「〜を実装した」という作業ログは除く
- 学びがない場合は何も出力しない（空行のみ）

---
$CONTEXT"

LEARNING=$(CLAUDE_LEARNING_EXTRACT=1 claude -p \
  --max-turns 2 \
  --dangerously-skip-permissions \
  "$PROMPT" 2>/dev/null | \
  grep -E '^- ' | \
  head -5 || true)

# ── Write to learnings file ────────────────────────────────────────────────
mkdir -p "$LEARNINGS_DIR"
[ ! -f "$LEARNINGS_FILE" ] && echo "# $DATE" > "$LEARNINGS_FILE"

{
  echo ""
  echo "## $TIME | $DIR"
  if [ -n "$LEARNING" ]; then
    echo "$LEARNING"
  else
    # No learnings extracted — write a minimal work log from git
    COMMITS=$(git -C "$CWD" log --oneline -3 2>/dev/null | sed 's/^/- /' || true)
    [ -n "$COMMITS" ] && echo "$COMMITS" || echo "- (作業内容なし)"
  fi
} >> "$LEARNINGS_FILE"

exit 0
