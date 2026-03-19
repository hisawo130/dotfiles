#!/bin/bash
# dotfiles セットアップスクリプト
# 新しいMacで実行: bash ~/dotfiles/setup.sh

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "🔧 dotfiles セットアップ開始..."

# Claude Code グローバル設定
echo "→ ~/.claude/CLAUDE.md のシンボリックリンク作成..."
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "  完了: ~/.claude/CLAUDE.md -> $DOTFILES_DIR/claude/CLAUDE.md"

echo "✅ セットアップ完了！"
