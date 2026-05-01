#!/bin/bash
# load-learnings.sh
# SessionStart hook: inject recent domain learnings into system message.
# Priority: [recurring] > [gotcha] > [correction] > [pattern]
# Also injects secondary domain gotchas when cross-domain session is detected.

LEARNINGS_DIR="$HOME/.claude/learnings"
LIB_DIR="$(dirname "$0")/lib"
NL=$'\n'

# ── Domain detection via shared library ───────────────────────────────────────
DETECT_CWD="$(pwd)"
# shellcheck source=lib/detect-domain.sh
source "$LIB_DIR/detect-domain.sh" 2>/dev/null || exit 0

DOMAIN_FILE="$LEARNINGS_DIR/${PRIMARY_DOMAIN}.md"
GENERAL_FILE="$LEARNINGS_DIR/general.md"

[ ! -f "$DOMAIN_FILE" ] && [ ! -f "$GENERAL_FILE" ] && exit 0

# ── Priority-sorted extraction ─────────────────────────────────────────────────
# Returns up to $max lines, highest-priority tags first, deduplicated.
extract_priority() {
  local file="$1" max="$2"
  {
    grep '\[recurring\]' "$file" 2>/dev/null | tail -3
    grep '\[gotcha\]'    "$file" 2>/dev/null | tail -4
    grep '\[correction\]' "$file" 2>/dev/null | tail -2
    grep '\[pattern\]'   "$file" 2>/dev/null | tail -2
  } | awk '!seen[$0]++' | head -"$max"
}

# ── Get last-updated date from a learnings file ────────────────────────────────
last_updated() {
  local file="$1"
  grep '^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$file" 2>/dev/null \
    | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1
}

# ── Build message parts ────────────────────────────────────────────────────────
DOMAIN_LINES=""
GENERAL_LINES=""
SECONDARY_LINES=""

if [ -f "$DOMAIN_FILE" ] && [ "$PRIMARY_DOMAIN" != "general" ]; then
  DOMAIN_LINES=$(extract_priority "$DOMAIN_FILE" 6)
fi

if [ -f "$GENERAL_FILE" ]; then
  GENERAL_LINES=$(extract_priority "$GENERAL_FILE" 3)
fi

# Inject top gotchas from secondary domains (e.g. matrixify during a Shopify session)
for sec_domain in "${SECONDARY_DOMAINS[@]}"; do
  [ -z "$sec_domain" ] && continue
  sec_file="$LEARNINGS_DIR/${sec_domain}.md"
  [ -f "$sec_file" ] || continue
  sec_lines=$(grep -E '\[recurring\]|\[gotcha\]' "$sec_file" 2>/dev/null | tail -2)
  [ -n "$sec_lines" ] && SECONDARY_LINES="${SECONDARY_LINES}（${sec_domain}）${NL}${sec_lines}${NL}"
done

[ -z "$DOMAIN_LINES" ] && [ -z "$GENERAL_LINES" ] && exit 0

# ── Assemble systemMessage ─────────────────────────────────────────────────────
MSG=""

if [ -n "$DOMAIN_LINES" ]; then
  _date=$(last_updated "$DOMAIN_FILE")
  _header="📚 前回の学習メモ [${PRIMARY_DOMAIN}]${_date:+ (最終: ${_date})}:"
  MSG="${_header}${NL}${DOMAIN_LINES}"
fi

if [ -n "$SECONDARY_LINES" ]; then
  MSG="${MSG}${NL}${SECONDARY_LINES}"
fi

if [ -n "$GENERAL_LINES" ]; then
  if [ -n "$MSG" ]; then
    MSG="${MSG}${NL}（general より）${NL}${GENERAL_LINES}"
  else
    MSG="📚 前回の学習メモ [general]:${NL}${GENERAL_LINES}"
  fi
fi

printf '%s' "$MSG" | jq -Rs '{"systemMessage": .}'
