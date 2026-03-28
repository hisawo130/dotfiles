#!/bin/bash
# lib/detect-domain.sh
# Shared domain detection library for save-learnings.sh and load-learnings.sh.
#
# Usage:
#   DETECT_CWD="$(pwd)" DETECT_TEXT="$combined_text" source "$(dirname "$0")/lib/detect-domain.sh"
#
# Outputs (as shell variables):
#   PRIMARY_DOMAIN   — main domain string (e.g. "shopify", "ecforce", "general")
#   SECONDARY_DOMAINS — bash array of additional domains detected from text keywords

PRIMARY_DOMAIN="general"
SECONDARY_DOMAINS=()

_cwd="${DETECT_CWD:-$(pwd)}"
_text="${DETECT_TEXT:-}"

# Resolve to git root for subdirectory robustness
_root=$(git -C "$_cwd" rev-parse --show-toplevel 2>/dev/null || echo "$_cwd")

# ── File-structure-based detection ────────────────────────────────────────────
if [ -f "$_root/shopify.theme.toml" ] || [ -f "$_root/config/settings_schema.json" ]; then
  PRIMARY_DOMAIN="shopify"
elif [ -d "$_root/ec_force" ] || [ -d "$_root/layouts/ec_force" ]; then
  PRIMARY_DOMAIN="ecforce"
elif [ -f "$_root/wp-config.php" ] || [ -d "$_root/wp-content" ]; then
  PRIMARY_DOMAIN="wordpress"
elif [ -f "$_root/package.json" ] && grep -q '"@shopify/hydrogen' "$_root/package.json" 2>/dev/null; then
  PRIMARY_DOMAIN="shopify-hydrogen"
elif [ -f "$_root/package.json" ] && grep -q '"@shopify/' "$_root/package.json" 2>/dev/null; then
  PRIMARY_DOMAIN="shopify-app"
elif [ -f "$_root/package.json" ] && grep -q '"next"' "$_root/package.json" 2>/dev/null; then
  PRIMARY_DOMAIN="react-nextjs"
elif [ -f "$_root/package.json" ] && grep -q '"nuxt"' "$_root/package.json" 2>/dev/null; then
  PRIMARY_DOMAIN="vue-nuxt"
elif [ -f "$_root/wrangler.toml" ] || [ -f "$_root/wrangler.jsonc" ]; then
  PRIMARY_DOMAIN="cloudflare"
elif [ -d "$_root/.github/workflows" ]; then
  PRIMARY_DOMAIN="github-actions"
elif [ -d "$_root/app/Plugin" ] || [ -f "$_root/app/config/eccube/config.yaml" ]; then
  PRIMARY_DOMAIN="ec-cube"
fi

# ── Keyword-based override (for general/non-project directories) ───────────────
if [ "$PRIMARY_DOMAIN" = "general" ] && [ -n "$_text" ]; then
  if echo "$_text" | grep -qiE '(shopify|liquid.*section|dawn theme|\{% schema %\}|storefront api)'; then
    PRIMARY_DOMAIN="shopify"
  elif echo "$_text" | grep -qiE '(ecforce|ec_force|file_root_path|\.html\.liquid)'; then
    PRIMARY_DOMAIN="ecforce"
  elif echo "$_text" | grep -qiE '(google analytics|gtm|ga4|dataLayer|google tag)'; then
    PRIMARY_DOMAIN="ga4-gtm"
  elif echo "$_text" | grep -qiE '(klaviyo|flow trigger|email segment)'; then
    PRIMARY_DOMAIN="klaviyo"
  elif echo "$_text" | grep -qiE '(matrixify|shopify export|csv import|bulkimport)'; then
    PRIMARY_DOMAIN="matrixify"
  elif echo "$_text" | grep -qiE '(github actions|workflow run|\.github/workflows)'; then
    PRIMARY_DOMAIN="github-actions"
  elif echo "$_text" | grep -qiE '(cloudflare|wrangler|workers|pages deploy)'; then
    PRIMARY_DOMAIN="cloudflare"
  elif echo "$_text" | grep -qiE '(make\.com|integromat|zapier|シナリオ|モジュール)'; then
    PRIMARY_DOMAIN="make-zapier"
  fi
fi

# ── Secondary domain detection (cross-domain sessions) ────────────────────────
if [ -n "$_text" ]; then
  echo "$_text" | grep -qiE '(matrixify|csv.*import|bulkimport)' \
    && [[ "$PRIMARY_DOMAIN" != "matrixify" ]] && SECONDARY_DOMAINS+=("matrixify")
  echo "$_text" | grep -qiE '(google analytics|gtm|ga4|dataLayer)' \
    && [[ "$PRIMARY_DOMAIN" != "ga4-gtm" ]] && SECONDARY_DOMAINS+=("ga4-gtm")
  echo "$_text" | grep -qiE '(klaviyo|flow trigger|email segment)' \
    && [[ "$PRIMARY_DOMAIN" != "klaviyo" ]] && SECONDARY_DOMAINS+=("klaviyo")
fi
