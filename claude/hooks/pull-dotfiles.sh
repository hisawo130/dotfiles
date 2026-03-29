#!/bin/bash
# pull-dotfiles.sh
# UserPromptSubmit hook: pull dotfiles once per session (cached).
# Uses a cache file to avoid repeated pulls within the same session.

_cache_dir="$HOME/.cache"
mkdir -p "$_cache_dir"
# Date-based flag: expires at midnight so dotfiles are pulled at most once per day
_today=$(date +%Y-%m-%d)
_flag="$_cache_dir/dotfiles_pull_${_today}"

if [ ! -f "$_flag" ]; then
  git -C "$HOME/dotfiles" pull --ff-only -q 2>/dev/null && touch "$_flag"
fi
