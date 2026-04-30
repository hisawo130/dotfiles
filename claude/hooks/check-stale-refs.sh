#!/bin/bash
# check-stale-refs.sh
# SessionStart hook: warn if reference files are 14+ days old.
# Outputs a systemMessage JSON if stale refs are found; silent otherwise.

REFS_DIR=""
LIB_DIR="$(dirname "$0")/lib"
# shellcheck source=lib/dotfiles-root.sh
source "$LIB_DIR/dotfiles-root.sh" 2>/dev/null
[ -n "${DOTFILES:-}" ] && REFS_DIR="$DOTFILES/claude/references"
[ -d "$REFS_DIR" ] || REFS_DIR="$HOME/dotfiles/claude/references"
[ -d "$REFS_DIR" ] || exit 0

STALE=$(find "$REFS_DIR" -name '*.md' -mtime +14 2>/dev/null | while read -r f; do
  _date=$(date -r "$f" +%Y-%m-%d 2>/dev/null || stat -f '%Sm' -t '%Y-%m-%d' "$f" 2>/dev/null)
  echo "$(basename "$f"): ${_date:-unknown}"
done)

[ -z "$STALE" ] && exit 0
jq -n --arg s "$STALE" '{"systemMessage": ("⚠️ 以下のリファレンスが14日以上未更新:\n" + $s)}'
