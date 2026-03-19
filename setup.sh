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

echo "→ ~/.claude/settings.json のシンボリックリンク作成..."
ln -sf "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
echo "  完了: ~/.claude/settings.json -> $DOTFILES_DIR/claude/settings.json"

echo "→ ~/.claude/agents のシンボリックリンク作成..."
ln -sf "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"
echo "  完了: ~/.claude/agents -> $DOTFILES_DIR/claude/agents"

echo "✅ セットアップ完了！"
