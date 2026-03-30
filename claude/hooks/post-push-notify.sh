#!/bin/bash
# PostToolUse hook: notify via ntfy after git push

NTFY_URL="${NTFY_TOPIC:-ntfy.sh/claude-2e88e2160d55}"
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Fast exit: only trigger on git push
echo "$CMD" | grep -qE 'git\s+push' || exit 0

REPO=$(basename "$(pwd)" 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
LATEST=$(git log --oneline -1 2>/dev/null || echo "N/A")

curl -s -m 5 \
  -H 'Title: Git Push' \
  -H 'Tags: rocket' \
  -H 'Priority: default' \
  -d "Repo: ${REPO} (${BRANCH})
Latest: ${LATEST}" \
  "https://${NTFY_URL}" 2>/dev/null || true
