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
ln -sfn "$DOTFILES/claude/learnings" "$HOME/.claude/learnings"
ln -sfn "$DOTFILES/claude/memory" "$HOME/.claude/memory"
ln -sfn "$DOTFILES/claude/tools" "$HOME/.claude/tools"
mkdir -p "$HOME/.claude/logs"
chmod +x "$DOTFILES"/claude/hooks/*.sh 2>/dev/null || true
chmod +x "$DOTFILES"/claude/hooks/lib/*.sh 2>/dev/null || true
chmod +x "$DOTFILES"/claude/tools/*.py 2>/dev/null || true
echo "  完了: ~/.claude/{CLAUDE.md,settings.json,agents,commands,hooks,references,learnings,memory,tools,logs}"

# --- 健全性チェック（doctor 走らせて即検証） ---
echo "→ 健全性チェック..."
if python3 "$DOTFILES/claude/tools/dotfiles-doctor.py" --check; then
  echo "  ✓ 全 symlink 正常"
else
  echo "  ⚠ 問題あり。doctor --verbose で確認してください"
fi

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
# export SHOPIFY_CLI_PARTNERS_TOKEN=""
EOF
  chmod 600 "$HOME/.secrets"
  echo "  作成: ~/.secrets"
else
  echo "  スキップ: ~/.secrets は既存"
fi

# --- Claude 認証 ---
echo "→ Claude 認証確認..."
if command -v claude &>/dev/null; then
  if claude auth status &>/dev/null; then
    echo "  ✓ 認証済み"
  else
    echo "  ブラウザで認証します..."
    claude auth login
  fi
else
  echo "  ⚠ claude コマンドが見つかりません。インストール後に: claude auth login"
fi

echo "✅ セットアップ完了！"
echo ""
echo "⚠️  手動対応が必要な項目:"
echo "   1. 新しいシェルを開く: exec zsh"
echo "   2. PATHに ~/.local/bin が含まれているか確認: echo \$PATH | grep .local"
