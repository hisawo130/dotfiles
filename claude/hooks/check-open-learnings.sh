#!/bin/bash
# check-open-learnings.sh
# Stop hook: summarize unresolved [open] entries from learnings files.
# Outputs a systemMessage if any [open] items exist.

LEARNINGS_DIR="$HOME/.claude/learnings"

open_items=$(grep -rh '\[open\]' "$LEARNINGS_DIR"/*.md 2>/dev/null | sed 's/^[[:space:]]*//' | head -10)

[ -z "$open_items" ] && exit 0

count=$(echo "$open_items" | wc -l | tr -d ' ')
jq -n --arg items "$open_items" --arg count "$count" \
  '{"systemMessage": ("📌 未解決の [open] 項目が " + $count + " 件あります:\n" + $items + "\n→ 次回セッションで対応を検討してください。")}'
