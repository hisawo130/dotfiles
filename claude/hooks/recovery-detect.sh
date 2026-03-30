#!/bin/bash
# recovery-detect.sh
# SessionStart hook: detect unclean shutdown (crash/force-quit/power loss)
# and inject recovery context.
#
# Logic:
#   - Normal exit  → Stop hook writes .session-clean marker
#   - Crash/kill   → Stop hook never runs → no marker
#   - SessionStart → if no marker + recent state.md → recovery mode

PROJ_DIR="$HOME/.claude/projects/$(pwd | sed 's|/|-|g')"
NL=$'\n'
STATE_FILE="$PROJ_DIR/state.md"
CLEAN_MARKER="$PROJ_DIR/.session-clean"

# Normal restart: clean marker exists → consume and exit silently
if [ -f "$CLEAN_MARKER" ]; then
  rm -f "$CLEAN_MARKER"
  exit 0
fi

# No state.md = no prior session context → skip
[ ! -f "$STATE_FILE" ] && exit 0

# Check state.md age — only trigger recovery within 24 hours
if [[ "$(uname)" == "Darwin" ]]; then
  STATE_MTIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo 0)
  LAST_UPDATE=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$STATE_FILE" 2>/dev/null || echo "不明")
else
  STATE_MTIME=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
  LAST_UPDATE=$(date -r "$STATE_FILE" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "不明")
fi
STATE_AGE=$(( $(date +%s) - STATE_MTIME ))
[ "$STATE_AGE" -gt 86400 ] && exit 0

# Collect uncommitted changes as recovery hint
GIT_DIRTY=$(git -C "$PWD" status --short 2>/dev/null | head -8 | sed 's/^/  /' || true)
GIT_STASH=$(git -C "$PWD" stash list 2>/dev/null | head -3 | sed 's/^/  /' || true)

# Build recovery message
MSG="🔄 **クラッシュリカバリー** — 前回セッションが正常終了していません${NL}"
MSG="${MSG}(state.md 最終更新: ${LAST_UPDATE})${NL}${NL}"

if [ -n "$GIT_DIRTY" ]; then
  MSG="${MSG}**未コミットの変更（中断ポイントの手がかり）:**${NL}${GIT_DIRTY}${NL}${NL}"
fi

if [ -n "$GIT_STASH" ]; then
  MSG="${MSG}**スタッシュあり:**${NL}${GIT_STASH}${NL}${NL}"
fi

MSG="${MSG}state.md の Focus / In Progress を確認して作業を再開してください。${NL}"
MSG="${MSG}クリアするには: rm \"${STATE_FILE}\""

jq -n --arg m "$MSG" '{"systemMessage": $m}'
exit 0
