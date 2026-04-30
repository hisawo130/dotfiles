#!/bin/bash
# dotfiles-root.sh
# Resolves the dotfiles repository root path.
#
# Resolution order:
#   1. $DOTFILES env var (if set and valid)
#   2. ~/.dotfiles-root file (written by setup.sh)
#   3. realpath of ~/.claude/CLAUDE.md symlink (parent of claude/)
#   4. fallback: $HOME/dotfiles
#
# Usage:
#   DOTFILES=$(bash "$LIB_DIR/dotfiles-root.sh")
# or sourced:
#   source "$LIB_DIR/dotfiles-root.sh"   # exports DOTFILES

resolve_dotfiles_root() {
  local candidate=""

  # 1. Env var
  if [ -n "${DOTFILES:-}" ] && [ -d "$DOTFILES/claude" ]; then
    echo "$DOTFILES"
    return 0
  fi

  # 2. Marker file written at setup
  if [ -f "$HOME/.dotfiles-root" ]; then
    candidate=$(head -1 "$HOME/.dotfiles-root" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$candidate" ] && [ -d "$candidate/claude" ]; then
      echo "$candidate"
      return 0
    fi
  fi

  # 3. Resolve via the CLAUDE.md symlink
  if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    local target
    target=$(readlink "$HOME/.claude/CLAUDE.md" 2>/dev/null)
    if [ -n "$target" ]; then
      # Make absolute if relative
      case "$target" in
        /*) ;;
        *)  target="$HOME/.claude/$target" ;;
      esac
      candidate=$(cd "$(dirname "$target")/.." 2>/dev/null && pwd)
      if [ -n "$candidate" ] && [ -d "$candidate/claude" ]; then
        echo "$candidate"
        return 0
      fi
    fi
  fi

  # 4. Fallback
  echo "$HOME/dotfiles"
  return 1
}

# If sourced, export DOTFILES; if executed, print to stdout.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  DOTFILES=$(resolve_dotfiles_root)
  export DOTFILES
else
  resolve_dotfiles_root
fi
