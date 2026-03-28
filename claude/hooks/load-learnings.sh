#!/bin/bash
# load-learnings.sh
# SessionStart hook: inject recent domain learnings into system message.
# Priority order: [recurring] > [gotcha] > [correction] > [pattern]

LEARNINGS_DIR="$HOME/.claude/learnings"
LIB_DIR="$(dirname "$0")/lib"

# ── Domain detection via shared library ───────────────────────────────────────
DETECT_CWD="$(pwd)"
# shellcheck source=lib/detect-domain.sh
source "$LIB_DIR/detect-domain.sh" 2>/dev/null || exit 0

DOMAIN_FILE="$LEARNINGS_DIR/${PRIMARY_DOMAIN}.md"
GENERAL_FILE="$LEARNINGS_DIR/general.md"

[ ! -f "$DOMAIN_FILE" ] && [ ! -f "$GENERAL_FILE" ] && exit 0

# ── Priority-sorted extraction ─────────────────────────────────────────────────
# Returns up to $max lines, highest-priority tags first.
extract_priority() {
  local file="$1" max="$2"
  {
    grep '\[recurring\]' "$file" 2>/dev/null | tail -3
    grep '\[gotcha\]'    "$file" 2>/dev/null | tail -4
    grep '\[correction\]' "$file" 2>/dev/null | tail -2
    grep '\[pattern\]'   "$file" 2>/dev/null | tail -2
  } | awk '!seen[$0]++' | head -"$max"
}

DOMAIN_LINES=""
GENERAL_LINES=""

if [ -f "$DOMAIN_FILE" ] && [ "$PRIMARY_DOMAIN" != "general" ]; then
  DOMAIN_LINES=$(extract_priority "$DOMAIN_FILE" 6)
fi
if [ -f "$GENERAL_FILE" ]; then
  GENERAL_LINES=$(extract_priority "$GENERAL_FILE" 3)
fi

[ -z "$DOMAIN_LINES" ] && [ -z "$GENERAL_LINES" ] && exit 0

# ── Build message ──────────────────────────────────────────────────────────────
MSG=""
if [ -n "$DOMAIN_LINES" ]; then
  MSG="📚 前回の学習メモ [${PRIMARY_DOMAIN}]:\n${DOMAIN_LINES}"
fi
if [ -n "$GENERAL_LINES" ]; then
  if [ -n "$MSG" ]; then
    MSG="${MSG}\n（general より）\n${GENERAL_LINES}"
  else
    MSG="📚 前回の学習メモ [general]:\n${GENERAL_LINES}"
  fi
fi

printf '%s' "$MSG" | jq -Rs '{"systemMessage": .}'
