#!/bin/bash
# pull-dotfiles.sh
# UserPromptSubmit hook: pull dotfiles once per day (cached).

LIB_DIR="$(dirname "$0")/lib"
# shellcheck source=lib/dotfiles-root.sh
source "$LIB_DIR/dotfiles-root.sh" 2>/dev/null
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

_cache_dir="/tmp/claude-dotfiles-pull"
mkdir -p "$_cache_dir"
_today=$(date +%Y-%m-%d)
_flag="$_cache_dir/dotfiles_pull_${_today}"

if [ ! -f "$_flag" ] && [ -d "$DOTFILES/.git" ]; then
  git -C "$DOTFILES" pull --ff-only -q 2>/dev/null && touch "$_flag"
fi
