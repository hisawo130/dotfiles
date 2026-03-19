# =============================================================================
# PATH
# =============================================================================

# Homebrew (Apple Silicon)
if [[ -d /opt/homebrew/bin ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Node via Homebrew (version-agnostic)
if command -v brew &>/dev/null && brew --prefix node &>/dev/null 2>&1; then
  export PATH="$(brew --prefix node)/bin:$PATH"
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
# Aliases
# =============================================================================
alias be="bundle exec"
alias bi="bundle install"
alias dc="docker compose"
