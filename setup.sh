#!/bin/bash
# dotfiles セットアップスクリプト
# 新しいMacで実行: bash ~/dotfiles/setup.sh

set -e

# スクリプトの場所から dotfiles ルートを自動検出
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 dotfiles セットアップ開始..."
echo "   DOTFILES=$DOTFILES"

# --- 前提チェック ---
if ! command -v git &>/dev/null; then
  echo "❌ git が見つかりません。先にインストールしてください。"
  exit 1
fi

# --- Claude Code ---
echo "→ Claude Code 設定..."
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
ln -sfn "$DOTFILES/claude/agents" "$HOME/.claude/agents"
ln -sfn "$DOTFILES/claude/commands" "$HOME/.claude/commands"
ln -sfn "$DOTFILES/claude/hooks" "$HOME/.claude/hooks"
ln -sfn "$DOTFILES/claude/references" "$HOME/.claude/references"
ln -sf "$DOTFILES/claude/statusline.py" "$HOME/.claude/statusline.py"
chmod +x "$DOTFILES"/claude/hooks/*.sh 2>/dev/null || true

# Memory: symlink to dotfiles so it syncs across machines
# Claude Code derives the project dir name by replacing / with - in $HOME
MEMORY_PROJECT_DIR=$(echo "$HOME" | tr '/' '-')
mkdir -p "$HOME/.claude/projects/$MEMORY_PROJECT_DIR"
# Backup existing real directory if present
if [ -d "$HOME/.claude/projects/$MEMORY_PROJECT_DIR/memory" ] && [ ! -L "$HOME/.claude/projects/$MEMORY_PROJECT_DIR/memory" ]; then
  mv "$HOME/.claude/projects/$MEMORY_PROJECT_DIR/memory" "$HOME/.claude/projects/$MEMORY_PROJECT_DIR/memory.bak.$(date +%Y%m%d%H%M%S)"
  echo "  既存 memory/ をバックアップ"
fi
ln -sfn "$DOTFILES/claude/memory" "$HOME/.claude/projects/$MEMORY_PROJECT_DIR/memory"
echo "  完了: ~/.claude/{CLAUDE.md,settings.json,agents,commands,hooks,references,statusline.py,memory}"

# --- scripts (claude-run 等) ---
echo "→ scripts 設定..."
chmod +x "$DOTFILES"/scripts/*.sh 2>/dev/null || true
ln -sfn "$DOTFILES/scripts" "$HOME/.local/bin/claude-scripts" 2>/dev/null || true
# PATH に含まれる場所へ claude-run のシンボリックリンクを作成
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/scripts/claude-run.sh" "$HOME/.local/bin/claude-run"
chmod +x "$HOME/.local/bin/claude-run" 2>/dev/null || true
echo "  完了: claude-run → ~/.local/bin/claude-run"

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
echo "   2. 新しいシェルを開く: exec zsh"
echo "   3. PATHに ~/.local/bin が含まれているか確認: echo \$PATH | grep .local"
