#!/bin/bash
# PreToolUse hook: block compound commands (&&, ||, ;) in Bash calls
# Allowed: pipes (|), for/if/while loops, conditional tests, subshells
# Blocked: top-level command chaining like "cmd1 && cmd2", "cmd1; cmd2"
#
# STATUS: opt-in. Not wired in claude/settings.json by default because it
# breaks common interactive patterns (e.g. `cd foo && ls`). To enable,
# add this entry to the PreToolUse > Bash hooks array in settings.json:
#   { "type": "command", "command": "bash $HOME/.claude/hooks/block-compound-commands.sh" }

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Fast exit: empty command
[ -z "$CMD" ] && exit 0

# Allow: single-line loops and conditionals (for, if, while, until, case)
# These are compound statements, not command chaining
if echo "$CMD" | grep -qE '^\s*(for|if|while|until|case)\s'; then
  exit 0
fi

# Allow: heredoc commands — content inside <<EOF...EOF can contain operators legitimately
# (e.g., git commit -m "$(cat <<'EOF'\nchore: fix && add\nEOF\n)")
if echo "$CMD" | grep -qF '<<'; then
  exit 0
fi

# Strip quoted strings to avoid false positives
STRIPPED=$(echo "$CMD" | sed \
  -e "s/'[^']*'//g" \
  -e 's/"[^"]*"//g' \
  -e 's/\$([^)]*)//g')

# Check for top-level compound operators
if echo "$STRIPPED" | grep -qE '&&|\|\||;'; then
  OP=$(echo "$STRIPPED" | grep -oE '&&|\|\||;' | head -1)
  jq -n --arg op "$OP" --arg cmd "$CMD" \
    '{"decision":"block","reason":("複合コマンド（" + $op + "）は禁止されています。各コマンドを個別のBash呼び出しに分割してください。\nブロックされたコマンド: " + $cmd)}'
  exit 0
fi

exit 0
