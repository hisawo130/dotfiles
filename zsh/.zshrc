# =============================================================================
# PATH
# =============================================================================

# Homebrew (Apple Silicon)
if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Node via Homebrew (version-agnostic)
BREW_NODE_PREFIX="$(brew --prefix node 2>/dev/null)"
if [[ -n "$BREW_NODE_PREFIX" && -d "$BREW_NODE_PREFIX/bin" ]]; then
  export PATH="$BREW_NODE_PREFIX/bin:$PATH"
fi

# npm global binaries
if command -v npm &>/dev/null; then
  NPM_GLOBAL_BIN="$(npm config get prefix)/bin"
  [[ -d "$NPM_GLOBAL_BIN" ]] && export PATH="$NPM_GLOBAL_BIN:$PATH"
fi

# =============================================================================
# Secrets — NOT stored in dotfiles
# Create ~/.secrets and add: export ANTHROPIC_API_KEY="sk-ant-..."
# =============================================================================
[[ -f ~/.secrets ]] && source ~/.secrets

# =============================================================================
# Shopify / ecforce dev
# =============================================================================
export EDITOR="code --wait"

# rbenv (ecforce / Rails)
if command -v rbenv &>/dev/null; then
  eval "$(rbenv init - zsh)"
fi

# nodenv
if command -v nodenv &>/dev/null; then
  eval "$(nodenv init -)"
fi

# =============================================================================
# Claude Code — dotfiles auto-sync on launch
# =============================================================================
claude() {
  git -C "$HOME/dotfiles" pull --ff-only --quiet 2>/dev/null || true
  command claude "$@"
}

# =============================================================================
# Aliases
# =============================================================================
alias be="bundle exec"
alias bi="bundle install"
alias dc="docker compose"

# git
alias gs="git status"
alias gl="git log --oneline -20"
alias gd="git diff"
alias ga="git add"
alias gp="git push"
