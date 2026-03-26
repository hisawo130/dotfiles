#!/bin/bash
# shopify-session-start.sh
# SessionStart hook: Shopifyテーマリポジトリで自動 git pull + 認証確認

CWD=$(pwd)

# Shopifyテーマリポジトリ以外はスキップ
if [ ! -f "$CWD/shopify.theme.toml" ] && [ ! -f "$CWD/config/settings_schema.json" ]; then
  exit 0
fi

# git pull --ff-only
PULL_OUT=$(git -C "$CWD" pull --ff-only 2>&1 | head -5)
PULL_STATUS=$?

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
