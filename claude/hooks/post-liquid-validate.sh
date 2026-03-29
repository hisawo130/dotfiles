#!/bin/bash
# Post-write validation for .liquid files (PostToolUse on Write/Edit)
# Outputs warnings for syntax issues. Does not block.

NL=$'\n'
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE=""

if [ "$TOOL" = "Write" ]; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
elif [ "$TOOL" = "Edit" ]; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
fi

# Fast exit: only check .liquid files
echo "$FILE" | grep -qE '\.liquid$' || exit 0
[ -f "$FILE" ] || exit 0

WARNINGS=""

# --- Check 1: Unmatched Liquid tags ---
for tag in if for unless case capture comment form paginate; do
  OPENS=$(grep -cE '\{%-?\s*'"$tag"'[\s%]' "$FILE" 2>/dev/null || echo 0)
  CLOSES=$(grep -cE '\{%-?\s*end'"$tag"'' "$FILE" 2>/dev/null || echo 0)
  if [ "$OPENS" -ne "$CLOSES" ]; then
    WARNINGS="${WARNINGS}${NL}⚠️ {% ${tag} %} タグ不一致 (open: ${OPENS}, close: ${CLOSES})"
  fi
done

# --- Check 2: {% include %} in Shopify OS 2.0 (should be {% render %}) ---
if [ -f "shopify.theme.toml" ] || [ -f "config/settings_schema.json" ]; then
  INCLUDES=$(grep -c '{% include ' "$FILE" 2>/dev/null || echo 0)
  if [ "$INCLUDES" -gt 0 ]; then
    WARNINGS="${WARNINGS}${NL}⚠️ {% include %} を${INCLUDES}箇所で検出。OS 2.0では {% render %} を使用してください"
  fi
fi

# --- Check 3: Hardcoded asset URLs (ecforce) ---
if [ -d "ec_force" ] || echo "$FILE" | grep -q "ec_force"; then
  HARDCODED=$(grep -cE 'https?://[^{]*\.(css|js|png|jpg|svg)' "$FILE" 2>/dev/null || echo 0)
  if [ "$HARDCODED" -gt 0 ]; then
    WARNINGS="${WARNINGS}${NL}⚠️ ハードコードされたアセットURLを${HARDCODED}箇所で検出。{{ file_root_path }} を使用してください"
  fi
fi

# --- Check 4: schema JSON validity (Shopify) ---
if grep -q '{% schema %}' "$FILE" 2>/dev/null; then
  SCHEMA=$(sed -n '/{% schema %}/,/{% endschema %}/p' "$FILE" | sed '1d;$d')
  echo "$SCHEMA" | jq . >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    WARNINGS="${WARNINGS}${NL}⚠️ {% schema %} のJSONが不正です。構文を確認してください"
  else
    # Check for duplicate setting IDs
    DUPES=$(echo "$SCHEMA" | jq -r '.. | .settings? // empty | .[].id' 2>/dev/null | sort | uniq -d)
    if [ -n "$DUPES" ]; then
      WARNINGS="${WARNINGS}${NL}⚠️ スキーマに重複するsetting IDがあります: $DUPES"
    fi
  fi
fi

if [ -n "$WARNINGS" ]; then
  printf '🔍 Liquid検証 (%s):%s\n' "$FILE" "$WARNINGS"
fi

exit 0
