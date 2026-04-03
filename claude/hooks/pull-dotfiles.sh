#!/bin/bash
# pull-dotfiles.sh
# UserPromptSubmit hook: pull dotfiles once per session (cached).
# Uses a cache file to avoid repeated pulls within the same session.

_cache_dir="/tmp/claude-dotfiles-pull"
mkdir -p "$_cache_dir"
# Session-based flag: use session_id from hook input so each session pulls once.
# Falls back to a per-process flag if session_id is unavailable.
_hook_input=$(cat /dev/stdin 2>/dev/null || true)
_session_id=$(echo "$_hook_input" | jq -r '.session_id // ""' 2>/dev/null || true)
_flag_key="${_session_id:-$$}"
_flag="$_cache_dir/pulled_${_flag_key}"

if [ ! -f "$_flag" ]; then
  git -C "$HOME/dotfiles" pull --rebase -q 2>/dev/null && touch "$_flag"
fi
