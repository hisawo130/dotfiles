#!/bin/bash
# dotfiles セットアップスクリプト
# 新しいMacで実行: bash ~/dotfiles/setup.sh

set -e

DOTFILES="$HOME/dotfiles"

echo "🔧 dotfiles セットアップ開始..."

# --- Claude Code ---
echo "→ Claude Code 設定..."
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
ln -sfn "$DOTFILES/claude/agents" "$HOME/.claude/agents"
ln -sfn "$DOTFILES/claude/commands" "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/projects/-Users-P130/memory"
echo "  完了: ~/.claude/{CLAUDE.md,settings.json,agents,commands,memory}"

# --- zsh ---
echo "→ zsh 設定..."
ZSHRC_DEST="$HOME/.zshrc"
ZSHRC_SRC="$DOTFILES/zsh/.zshrc"
if [[ -f "$ZSHRC_DEST" && ! -L "$ZSHRC_DEST" ]]; then
  BACKUP="$ZSHRC_DEST.bak.$(date +%Y%m%d%H%M%S)"
  echo "  既存 .zshrc をバックアップ → $BACKUP"
  mv "$ZSHRC_DEST" "$BACKUP"
fi
ln -sfn "$ZSHRC_SRC" "$ZSHRC_DEST"
echo "  完了: ~/.zshrc"

# --- gitignore_global ---
echo "→ git グローバル設定..."
GITIGNORE_DEST="$HOME/.gitignore_global"
GITIGNORE_SRC="$DOTFILES/git/.gitignore_global"
if [[ -f "$GITIGNORE_DEST" && ! -L "$GITIGNORE_DEST" ]]; then
  BACKUP="$GITIGNORE_DEST.bak.$(date +%Y%m%d%H%M%S)"
  echo "  既存 .gitignore_global をバックアップ → $BACKUP"
  mv "$GITIGNORE_DEST" "$BACKUP"
fi
ln -sfn "$GITIGNORE_SRC" "$GITIGNORE_DEST"

# git config (冪等)
git config --global core.excludesfile "$HOME/.gitignore_global"
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global init.defaultBranch main
echo "  完了: .gitignore_global + git config"

# --- secrets stub ---
echo "→ シークレット設定..."
if [[ ! -f "$HOME/.secrets" ]]; then
  cat > "$HOME/.secrets" <<'EOF'
# ローカルシークレット — このファイルは絶対にコミットしない
# export ANTHROPIC_API_KEY=""
# export SHOPIFY_CLI_PARTNERS_TOKEN=""
EOF
  chmod 600 "$HOME/.secrets"
  echo "  作成: ~/.secrets (APIキーを追記してください)"
else
  echo "  スキップ: ~/.secrets は既存"
fi

echo "✅ セットアップ完了！"
echo ""
echo "⚠️  手動対応が必要な項目:"
echo "   1. ~/.secrets に ANTHROPIC_API_KEY 等を追記"
echo "   2. ~/.zshrc.bak.* を確認し不要なら削除"
echo "   3. ~/.zprofile の重複 PATH エントリを手動で整理"
