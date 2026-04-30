#!/bin/bash
# ecforce-session-start.sh
# SessionStart hook: ecforceテーマリポジトリで git pull + テーマ複製リマインダー注入

CWD=$(pwd)

# ecforceリポジトリ以外はスキップ
if [ ! -d "$CWD/ec_force" ] && [ ! -d "$CWD/layouts/ec_force" ]; then
  exit 0
fi

# git pull — 当日1回のみ（複数セッション起動時のネットワーク待機を防ぐ）
_repo=$(basename "$CWD")
_today=$(date +%Y-%m-%d)
_cache_dir="$HOME/.cache"
mkdir -p "$_cache_dir"
_flag="${_cache_dir}/ecforce_pull_${_repo}_${_today}"

if [ ! -f "$_flag" ]; then
  PULL_RAW=$(git -C "$CWD" pull --ff-only 2>&1)
  PULL_STATUS=$?
  PULL_OUT=$(printf '%s\n' "$PULL_RAW" | head -5)
  [ "$PULL_STATUS" -eq 0 ] && touch "$_flag"
else
  PULL_OUT="(skipped — already pulled today)"
  PULL_STATUS=0
fi

if [ $PULL_STATUS -eq 0 ]; then
  PULL_MSG="📦 git pull: OK"
else
  PULL_MSG="⚠️ git pull失敗: $(echo "$PULL_OUT" | head -c 120)"
fi

MSG="🛒 ecforce Theme | ${PULL_MSG} | ⚠️ 編集前にテーマを複製しましたか？（保存=即本番反映）"

jq -n --arg m "$MSG" '{"systemMessage": $m}'
exit 0
