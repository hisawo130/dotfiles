#!/bin/bash
# shopify-session-start.sh
# SessionStart hook: Shopifyテーマリポジトリで自動 git pull + 認証確認

CWD=$(pwd)

# Shopifyテーマリポジトリ以外はスキップ
if [ ! -f "$CWD/shopify.theme.toml" ] && [ ! -f "$CWD/config/settings_schema.json" ]; then
  exit 0
fi

# git pull — 当日1回のみ（複数セッション起動時のネットワーク待機を防ぐ）
_repo=$(basename "$CWD")
_today=$(date +%Y-%m-%d)
_cache_dir="$HOME/.cache"
mkdir -p "$_cache_dir"
_flag="${_cache_dir}/shopify_pull_${_repo}_${_today}"

if [ ! -f "$_flag" ]; then
  PULL_RAW=$(git -C "$CWD" pull --ff-only 2>&1)
  PULL_STATUS=$?
  PULL_OUT=$(printf '%s\n' "$PULL_RAW" | head -5)
  [ "$PULL_STATUS" -eq 0 ] && touch "$_flag"
else
  PULL_OUT="(skipped — already pulled today)"
  PULL_STATUS=0
fi

# Shopify CLI 認証確認
WHO=$(shopify whoami 2>/dev/null | head -1 | tr -d '\n' || echo "")

# 認証メッセージ
if [ -n "$WHO" ]; then
  AUTH_MSG="🔐 ${WHO}"
else
  AUTH_MSG="⚠️ Shopify未認証 — ! shopify auth login を実行してください"
fi

# git pull メッセージ
if [ $PULL_STATUS -eq 0 ]; then
  PULL_MSG="📦 git pull: OK"
else
  PULL_MSG="⚠️ git pull失敗: $(echo "$PULL_OUT" | head -c 120)"
fi

jq -n --arg m "🛍️ Shopify Theme | ${AUTH_MSG} | ${PULL_MSG}" '{"systemMessage": $m}'
exit 0
