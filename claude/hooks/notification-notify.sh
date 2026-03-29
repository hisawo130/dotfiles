#!/bin/bash
# Notification hook: desktop notification + ntfy when Claude is waiting for input

NTFY_URL="${NTFY_TOPIC:-ntfy.sh/claude-2e88e2160d55}"

osascript -e 'display notification "Claude Codeが入力待ちです" with title "Claude Code" sound name "Ping"' 2>/dev/null

curl -s -m 5 \
  -H 'Title: Claude Code' \
  -H 'Tags: bell' \
  -d '入力待ちです' \
  "https://${NTFY_URL}" 2>/dev/null || true
