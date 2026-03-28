#!/bin/bash
# check-stale-refs.sh
# SessionStart hook: warn if reference files are 14+ days old.
# Outputs a systemMessage JSON if stale refs are found; silent otherwise.

REFS_DIR="${DOTFILES:-$HOME/dotfiles}/claude/references"
[ -d "$REFS_DIR" ] || exit 0

STALE=$(find "$REFS_DIR" -name '*.md' -mtime +14 2>/dev/null | while read -r f; do
  _date=$(date -r "$f" +%Y-%m-%d 2>/dev/null || stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null)
  echo "$(basename "$f"): ${_date:-unknown}"
done)

[ -z "$STALE" ] && exit 0
jq -n --arg s "$STALE" '{"systemMessage": ("⚠️ 以下のリファレンスが14日以上未更新:\n" + $s)}'
