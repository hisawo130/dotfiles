#!/bin/bash
# PreToolUse hook: block compound commands containing dangerous operations
# Safe compounds (no deny-list patterns) are allowed through
#
# Blocked: && || ; chains that contain any of:
#   rm -rf /~.*  |  git push --force/-f  |  git reset --hard
#   sudo rm/chmod  |  > /dev/sda

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Fast exit: empty command
[ -z "$CMD" ] && exit 0

# Allow: single-line loops and conditionals (for, if, while, until, case)
if echo "$CMD" | grep -qE '^\s*(for|if|while|until|case)\s'; then
  exit 0
fi

# Strip quoted strings to avoid false positives inside quoted arguments
STRIPPED=$(echo "$CMD" | sed \
  -e "s/'[^']*'//g" \
  -e 's/"[^"]*"//g' \
  -e 's/\$([^)]*)//g')

# Strip heredoc content: remove lines from << marker through EOF-style terminator
# This prevents commit message text from triggering deny patterns
STRIPPED=$(printf '%s\n' "$STRIPPED" | awk '
  !heredoc && /<</ { sub(/<<.*/, ""); heredoc=1; print; next }
  heredoc && /^[[:space:]]*[A-Za-z_][A-Za-z_0-9]*[[:space:]]*$/ { heredoc=0; next }
  heredoc { next }
  { print }
')

# Fast exit: no compound operators — nothing to check
if ! echo "$STRIPPED" | grep -qE '&&|\|\||;'; then
  exit 0
fi

# Compound command detected — scan for deny-list patterns
# Any match blocks the entire command
DENY_PATTERN='rm[[:space:]]+-rf[[:space:]]+[/~.*]|git[[:space:]]+push[[:space:]]+(-f\b|--force)|git[[:space:]]+reset[[:space:]]+--hard|sudo[[:space:]]+(rm|chmod)|>[[:space:]]*/dev/sda'

if echo "$STRIPPED" | grep -qE "$DENY_PATTERN"; then
  jq -n --arg cmd "$CMD" \
    '{"decision":"block","reason":("危険な操作を含む複合コマンドはブロックされました。\nコマンド: " + $cmd)}'
  exit 0
fi

# All parts passed deny-list checks — allow
exit 0
