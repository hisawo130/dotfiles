#!/bin/bash
# PreToolUse hook: block compound commands (&&, ||, ;) in Bash calls
# Pipes (|) are allowed. Operators inside quoted strings are allowed.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Fast exit: empty command
[ -z "$CMD" ] && exit 0

# Strip quoted strings to avoid false positives
# Remove single-quoted strings: 'anything'
# Remove double-quoted strings: "anything" (including escaped quotes)
# Remove $() subshells and heredocs content
STRIPPED=$(echo "$CMD" | sed \
  -e "s/'[^']*'//g" \
  -e 's/"[^"]*"//g' \
  -e 's/\$([^)]*)//g')

# Check for compound operators in unquoted context
if echo "$STRIPPED" | grep -qE '&&|\|\||;'; then
  # Extract the specific operator found
  OP=$(echo "$STRIPPED" | grep -oE '&&|\|\||;' | head -1)
  jq -n --arg op "$OP" --arg cmd "$CMD" \
    '{"decision":"block","reason":("複合コマンド（" + $op + "）は禁止されています。各コマンドを個別のBash呼び出しに分割してください。\nブロックされたコマンド: " + $cmd)}'
  exit 0
fi

exit 0
