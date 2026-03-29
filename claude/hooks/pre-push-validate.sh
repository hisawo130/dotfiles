#!/bin/bash
# Pre-push validation hook for Claude Code (PreToolUse on Bash)
# Blocks git push if validation fails. Fast exit for non-push commands.

NL=$'\n'
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Fast exit: only intercept git push commands
echo "$CMD" | grep -qE 'git\s+push' || exit 0

# --- Check 1: Shopify theme check ---
# Use git repo root so this works even when invoked from a subdirectory
_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -f "$_GIT_ROOT/shopify.theme.toml" ] || [ -f "$_GIT_ROOT/config/settings_schema.json" ]; then
  if command -v shopify >/dev/null 2>&1; then
    RESULT=$(cd "$_GIT_ROOT" && shopify theme check --fail-level error 2>&1)
    if [ $? -ne 0 ]; then
      ERRORS=$(echo "$RESULT" | grep -E '^\s*(✗|×|ERROR)' | head -10)
      jq -n --arg reason "shopify theme check でエラー検出。push前に修正してください:${NL}${ERRORS}" \
        '{"decision":"block","reason":$reason}'
      exit 0
    fi
  fi
fi

# --- Check 2: Sensitive files in staged area ---
STAGED=$(git diff --cached --name-only 2>/dev/null)
if echo "$STAGED" | grep -qE '(settings_data\.json|\.env|credentials|secret)'; then
  MATCHED=$(echo "$STAGED" | grep -E '(settings_data\.json|\.env|credentials|secret)')
  jq -n --arg reason "機密ファイルがステージされています。unstageしてください:${NL}${MATCHED}" \
    '{"decision":"block","reason":$reason}'
  exit 0
fi

# --- Check 3: Uncommitted changes (non-blocking warning) ---
# git push succeeds even with uncommitted changes; this is purely informational.
# Blocking here would create an infinite loop since the condition doesn't clear automatically.
DIRTY=$(git diff --name-only 2>/dev/null | head -5)
if [ -n "$DIRTY" ]; then
  COUNT=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  echo "⚠️  push実行: 追跡ファイルに未コミットの変更が${COUNT}件あります" >&2
fi

exit 0
