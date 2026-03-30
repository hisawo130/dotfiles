#!/bin/bash
# PermissionRequest hook: notify via ntfy when Claude needs approval for a tool

NTFY_URL="${NTFY_TOPIC:-ntfy.sh/claude-2e88e2160d55}"

TOOL=$(cat | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

curl -s -m 5 \
  -H 'Title: 承認待ち' \
  -H 'Priority: high' \
  -H 'Tags: rotating_light' \
  -d "${TOOL} の実行に承認が必要です" \
  "https://${NTFY_URL}" 2>/dev/null || true
