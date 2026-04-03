#!/bin/bash
# Session end hook: summarize changes and notify via ntfy

NTFY_URL="${NTFY_TOPIC:-ntfy.sh/claude-2e88e2160d55}"

echo '─── session end ───'

# Collect session summary
COMMITS=$(git -C "$(pwd)" log --oneline -5 2>/dev/null || echo "N/A")
UNCOMMITTED=$(git -C "$(pwd)" status --short 2>/dev/null | head -15)
REPO=$(basename "$(pwd)" 2>/dev/null || echo "unknown")

echo '[commits]'
echo "$COMMITS"
echo '[uncommitted]'
echo "$UNCOMMITTED"

# Dotfiles sync (claude/ and scripts/ only — avoid accidentally staging project files)
echo '[dotfiles]'
_d="$HOME/dotfiles"
git -C "$_d" add "claude/" "scripts/" ".github/" 2>/dev/null || true
_s=$(git -C "$_d" diff --cached --name-only 2>/dev/null)
if [ -n "$_s" ]; then
  git -C "$_d" commit -m 'chore: セッション終了時の自動同期' 2>/dev/null
fi
_u=$(git -C "$_d" log --oneline @{u}..HEAD 2>/dev/null)
if [ -n "$_u" ]; then
  # Pull with rebase before push to avoid non-fast-forward errors.
  # learnings/*.md uses merge=union driver so conflicts auto-resolve.
  if ! git -C "$_d" pull --rebase -q 2>/dev/null; then
    git -C "$_d" rebase --abort 2>/dev/null
  fi
  git -C "$_d" push 2>/dev/null && echo 'dotfiles pushed'
fi
git -C "$_d" log --oneline -1 2>/dev/null

# Notify via ntfy
COMMIT_COUNT=$(git -C "$(pwd)" log --oneline -5 2>/dev/null | wc -l | tr -d ' ')
UNCOMMIT_COUNT=$(git -C "$(pwd)" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
SUMMARY="Repo: ${REPO}
Commits(5): ${COMMIT_COUNT}
Uncommitted: ${UNCOMMIT_COUNT}"

if [ -n "$UNCOMMITTED" ]; then
  SUMMARY="${SUMMARY}
${UNCOMMITTED}"
fi

curl -s -m 5 \
  -H 'Title: Session End' \
  -H 'Tags: checkered_flag' \
  -d "$SUMMARY" \
  "https://${NTFY_URL}" 2>/dev/null || true

# Write clean session marker for recovery-detect.sh
# Without this, recovery-detect.sh would show a false crash warning next session
_proj_dir="$HOME/.claude/projects/$(echo "$(pwd)" | sed 's|/|-|g')"
mkdir -p "$_proj_dir"
touch "$_proj_dir/.session-clean"
