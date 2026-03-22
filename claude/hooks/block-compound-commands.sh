#!/bin/bash
# PreToolUse hook: block compound commands containing dangerous operations
# Safe compounds (no deny-list patterns) are allowed through
#
# Blocked patterns:
#   rm (any flags) targeting /~.*   |  git push --force/-f (not --force-with-lease)
#   git reset --hard                |  sudo rm/chmod
#   write to any /dev/ device

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

[ -z "$CMD" ] && exit 0

# Allow: single-line loops and conditionals (for, if, while, until, case)
if echo "$CMD" | grep -qE '^\s*(for|if|while|until|case)\s'; then
  exit 0
fi

# Strip all quoted strings (including multi-line) using perl slurp mode
# This prevents commit message text from triggering deny patterns
STRIPPED=$(printf '%s\n' "$CMD" | perl -0777 \
  -pe 's/".*?"//gs; s/'"'"'[^'"'"']*'"'"'//g; s/\$\([^)]*\)//g')

# Strip heredoc content (between << marker and EOF-style terminator)
# Handles $(cat <<'EOF'...EOF) pattern after quote stripping
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

BLOCKED=0

# 1. rm targeting dangerous paths
#    Handles: -rf, -Rf, -fR, -r -f, -- separator, any case combination
if echo "$STRIPPED" | grep -qE 'rm([[:space:]]+-[a-zA-Z]+)*([[:space:]]+--)?[[:space:]]+[/~.*]'; then
  BLOCKED=1
fi

# 2. git push with --force or -f
#    Strip --force-with-lease first to avoid false positive
#    Match --force or -f anywhere in the push command
if [ "$BLOCKED" -eq 0 ] && echo "$STRIPPED" | grep -qE 'git[[:space:]]+push'; then
  PUSH_STRIPPED=$(echo "$STRIPPED" | sed 's/--force-with-lease//g')
  if echo "$PUSH_STRIPPED" | grep -qE 'git[[:space:]]+push.*--force'; then
    BLOCKED=1
  fi
  if [ "$BLOCKED" -eq 0 ] && echo "$PUSH_STRIPPED" | grep -qE 'git[[:space:]]+push.*[[:space:]]-f([[:space:]]|$)'; then
    BLOCKED=1
  fi
fi

# 3. git reset --hard
if [ "$BLOCKED" -eq 0 ] && echo "$STRIPPED" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
  BLOCKED=1
fi

# 4. sudo rm or sudo chmod
if [ "$BLOCKED" -eq 0 ] && echo "$STRIPPED" | grep -qE 'sudo[[:space:]]+(rm|chmod)'; then
  BLOCKED=1
fi

# 5. Write to any /dev/ device (not just /dev/sda)
# Exclude /dev/null which is safe for output suppression (2>/dev/null, >/dev/null)
if [ "$BLOCKED" -eq 0 ]; then
  DEVCHECK=$(echo "$STRIPPED" | sed 's/[0-9]*>[[:space:]]*\/dev\/null//g')
  if echo "$DEVCHECK" | grep -qE '>[[:space:]]*/dev/'; then
    BLOCKED=1
  fi
fi

if [ "$BLOCKED" -eq 1 ]; then
  jq -n --arg cmd "$CMD" \
    '{"decision":"block","reason":("危険な操作を含む複合コマンドはブロックされました。\nコマンド: " + $cmd)}'
  exit 0
fi

# All parts passed deny-list checks — allow
exit 0
