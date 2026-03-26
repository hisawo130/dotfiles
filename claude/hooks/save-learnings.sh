#!/bin/bash
# save-learnings.sh
# Claude Code Stop hook: extract session learnings and save by domain.
# Writes to ~/.claude/learnings/<domain>.md (not date-based).

# Recursion guard
[ "${CLAUDE_LEARNING_EXTRACT:-}" = "1" ] && exit 0

# ── Config ────────────────────────────────────────────────────────────────
LEARNINGS_DIR="$HOME/.claude/learnings"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
CWD=$(pwd)
DIR=$(basename "$CWD")
MAX_TRANSCRIPT_CHARS=6000

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

# ── Extract text content from transcript ──────────────────────────────────
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

# ── Detect domain hint from project structure ──────────────────────────────
DOMAIN_HINT="general"
if [ -f "$CWD/shopify.theme.toml" ] || [ -f "$CWD/config/settings_schema.json" ]; then
  DOMAIN_HINT="shopify"
elif [ -d "$CWD/ec_force" ] || [ -d "$CWD/layouts/ec_force" ]; then
  DOMAIN_HINT="ecforce"
elif [ -f "$CWD/wp-config.php" ] || [ -d "$CWD/wp-content" ]; then
  DOMAIN_HINT="wordpress"
elif [ -f "$CWD/package.json" ] && grep -q '"@shopify/hydrogen' "$CWD/package.json" 2>/dev/null; then
  DOMAIN_HINT="shopify-hydrogen"
elif [ -f "$CWD/package.json" ] && grep -q '"@shopify/' "$CWD/package.json" 2>/dev/null; then
  DOMAIN_HINT="shopify-app"
elif [ -f "$CWD/package.json" ] && grep -q '"next"' "$CWD/package.json" 2>/dev/null; then
  DOMAIN_HINT="react-nextjs"
elif [ -f "$CWD/package.json" ] && grep -q '"nuxt"' "$CWD/package.json" 2>/dev/null; then
  DOMAIN_HINT="vue-nuxt"
elif [ -f "$CWD/wrangler.toml" ] || [ -f "$CWD/wrangler.jsonc" ]; then
  DOMAIN_HINT="cloudflare"
elif [ -d "$CWD/.github/workflows" ]; then
  DOMAIN_HINT="github-actions"
elif [ -d "$CWD/app/Plugin" ] || [ -f "$CWD/app/config/eccube/config.yaml" ]; then
  DOMAIN_HINT="ec-cube"
fi

# ── Extract learnings + domain via claude -p ──────────────────────────────
PROMPT="以下はClaudeセッションの会話ログです。

【出力フォーマット — 必ずこの形式を守ること】
DOMAIN: <domain>
- 学び1（あれば）
- 学び2（あれば）
- 学び3（あれば）

【domainの選択肢】
ログの内容に最も合うものを1つ選ぶ（デフォルトヒント: ${DOMAIN_HINT}）:
- shopify          … Shopifyテーマ・Liquid・セクション・Dawn・OS2.0
- shopify-app      … Shopifyカスタムアプリ・Storefront API・Functions・GraphQL
- shopify-flow     … Shopify Flowワークフロー・トリガー・アクション
- shopify-extensions … Theme App/Checkout UI/Customer Account Extensions
- shopify-hydrogen … Hydrogen・Oxygen・ヘッドレスStorefront
- shopify-webhooks … Webhooks・Metafields・Metaobjects
- ecforce          … ecforceテンプレート・Liquid・スマホ版
- wordpress        … WordPress・WooCommerce・テーマ・プラグイン
- ec-cube          … EC-CUBE 4系・Symfony・Twig・プラグイン
- matrixify        … MatrixifyのCSV/Excelインポート・エクスポート・データ移行
- ga4-gtm          … Google Analytics 4・GTM・イベント計測・コンバージョン
- klaviyo          … Klaviyoメール/SMS・フロー・セグメント・Shopify連携
- line             … LINE公式アカウント・LINE API・Messaging API
- react-nextjs     … React・Next.js・App Router・TypeScript
- vue-nuxt         … Vue.js・Nuxt・Composition API
- github-actions   … CI/CD・GitHub Actionsワークフロー
- cloudflare       … DNS・CDN・Pages・Workers・リダイレクト
- make-zapier      … Make(Integromat)・Zapier・ノーコード自動化
- cms              … microCMS・Contentful・Storyblok・ヘッドレスCMS
- stripe           … Stripe決済API・Webhook・サブスクリプション
- general          … ツール・git・CLI・複数領域横断・その他

【学びの抽出ルール】
- 具体的・非自明なもののみ（プラットフォーム固有の罠、バグの根本原因、有効だったパターン、ユーザーが修正した誤り）
- 最大3つ、日本語箇条書き（- で始める）
- 汎用アドバイス・自明な内容・作業ログは含めない
- 学びがなければ「DOMAIN: ${DOMAIN_HINT}」のみ出力（学び行なし）

---
$CONTEXT"

RAW=$(CLAUDE_LEARNING_EXTRACT=1 claude -p \
  --max-turns 2 \
  --dangerously-skip-permissions \
  "$PROMPT" 2>/dev/null || true)

[ -z "$RAW" ] && exit 0

# ── Parse domain and learnings ────────────────────────────────────────────
DOMAIN=$(echo "$RAW" | grep '^DOMAIN:' | head -1 | sed 's/^DOMAIN: *//' | tr -d '[:space:][:cntrl:]')
LEARNING=$(echo "$RAW" | grep '^- ' | head -5)

# Validate domain
VALID_DOMAINS="shopify shopify-app shopify-flow shopify-extensions shopify-hydrogen shopify-webhooks ecforce wordpress ec-cube matrixify ga4-gtm klaviyo line react-nextjs vue-nuxt github-actions cloudflare make-zapier cms stripe general"
echo "$VALID_DOMAINS" | grep -qw "${DOMAIN:-}" || DOMAIN="$DOMAIN_HINT"

DOMAIN_FILE="$LEARNINGS_DIR/${DOMAIN}.md"

# ── Write to domain file ───────────────────────────────────────────────────
mkdir -p "$LEARNINGS_DIR"

if [ ! -f "$DOMAIN_FILE" ]; then
  echo "# $(echo "$DOMAIN" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1') Learnings" > "$DOMAIN_FILE"
fi

if [ -n "$LEARNING" ]; then
  {
    echo ""
    echo "## $DATE $TIME | $DIR"
    echo "$LEARNING"
  } >> "$DOMAIN_FILE"
else
  exit 0
fi

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
