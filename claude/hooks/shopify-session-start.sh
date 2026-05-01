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

# .envrc の SHOPIFY_FLAG_STORE チェック
STORE_MSG=""
STORE_CONTEXT=""
if [ -f "$CWD/.envrc" ] && grep -q 'SHOPIFY_FLAG_STORE' "$CWD/.envrc" 2>/dev/null; then
  STORE=$(grep 'SHOPIFY_FLAG_STORE' "$CWD/.envrc" | head -1 | sed 's/.*=//;s/"//g;s/'"'"'//g;s/ *$//')
  STORE_MSG="🏪 store: ${STORE}"
else
  STORE_MSG="⚠️ SHOPIFY_FLAG_STORE未設定"
  STORE_CONTEXT="このShopifyプロジェクト($CWD)には .envrc の SHOPIFY_FLAG_STORE が設定されていません。セッション開始時にユーザーに日本語で「このプロジェクトのShopifyストアドメイン（xxx.myshopify.com）を教えてください。.envrcに設定します」と質問してください。"
fi

SYS_MSG="🛍️ Shopify Theme | ${AUTH_MSG} | ${PULL_MSG} | ${STORE_MSG}"

if [ -n "$STORE_CONTEXT" ]; then
  jq -n --arg m "$SYS_MSG" --arg c "$STORE_CONTEXT" \
    '{"systemMessage": $m, "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": $c}}'
else
  jq -n --arg m "$SYS_MSG" '{"systemMessage": $m}'
fi
exit 0
