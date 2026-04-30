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

# ~/.local/bin (claude-run 等のカスタムスクリプト)
export PATH="$HOME/.local/bin:$PATH"

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
# Resolve dotfiles location once: marker file → CLAUDE.md symlink → fallback
if [[ -f "$HOME/.dotfiles-root" ]]; then
  export DOTFILES="$(head -1 "$HOME/.dotfiles-root" 2>/dev/null)"
elif [[ -L "$HOME/.claude/CLAUDE.md" ]]; then
  export DOTFILES="$(cd "$(dirname "$(readlink "$HOME/.claude/CLAUDE.md")")/.." 2>/dev/null && pwd)"
fi
[[ -z "$DOTFILES" || ! -d "$DOTFILES/claude" ]] && export DOTFILES="$HOME/dotfiles"

claude() {
  [[ -d "$DOTFILES/.git" ]] && git -C "$DOTFILES" pull --ff-only --quiet 2>/dev/null || true
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
alias gc="git commit"
alias gco="git checkout"
alias gb="git branch"
alias gpl="git pull"
alias glog="git log --oneline --graph --all -30"

# =============================================================================
# Project detection helper — prints project type on cd
# =============================================================================
_detect_project_type() {
  local dir="${1:-$(pwd)}"
  if [[ -f "$dir/shopify.theme.toml" || -f "$dir/config/settings_schema.json" ]]; then
    echo "shopify-theme"
  elif [[ -d "$dir/ec_force" || -d "$dir/layouts/ec_force" ]]; then
    echo "ecforce"
  elif [[ -f "$dir/package.json" ]] && grep -q '@shopify/' "$dir/package.json" 2>/dev/null; then
    echo "shopify-app"
  else
    echo "generic"
  fi
}

# Auto-announce project type when changing into a known project directory
chpwd() {
  local type
  type=$(_detect_project_type "$(pwd)")
  case "$type" in
    shopify-theme) echo "🛍  Shopify theme" ;;
    ecforce)       echo "🏪 ecforce theme" ;;
    shopify-app)   echo "⚙️  Shopify app" ;;
  esac
}
