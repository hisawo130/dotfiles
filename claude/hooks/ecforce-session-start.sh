#!/bin/bash
# ecforce-session-start.sh
# SessionStart hook: ecforceテーマリポジトリで git pull + テーマ複製リマインダー注入

CWD=$(pwd)

# ecforceリポジトリ以外はスキップ
if [ ! -d "$CWD/ec_force" ] && [ ! -d "$CWD/layouts/ec_force" ]; then
  exit 0
fi

# git pull --ff-only
PULL_OUT=$(git -C "$CWD" pull --ff-only 2>&1 | head -5)
PULL_STATUS=$?

if [ $PULL_STATUS -eq 0 ]; then
  PULL_MSG="📦 git pull: OK"
else
  PULL_MSG="⚠️ git pull失敗: $(echo "$PULL_OUT" | head -c 120)"
fi

MSG="🛒 ecforce Theme | ${PULL_MSG} | ⚠️ 編集前にテーマを複製しましたか？（保存=即本番反映）"

jq -n --arg m "$MSG" '{"systemMessage": $m}'
exit 0
