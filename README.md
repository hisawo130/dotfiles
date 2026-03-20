# dotfiles

macOS 開発環境の設定ファイル。Claude Code / Shopify / ecforce 開発に最適化。

## セットアップ

```bash
git clone https://github.com/hisawo130/dotfiles.git ~/dotfiles
bash ~/dotfiles/setup.sh
```

## 構成

```
claude/
  CLAUDE.md          # グローバル指示（システムプロンプト）
  settings.json      # 権限・フック・effortLevel
  agents/            # サブエージェント定義（planner / executor / researcher / reviewer）
  commands/          # スラッシュコマンド（/shopify-pr, /ecforce-checklist, /context-load 等）
  references/        # プラットフォームリファレンス（Shopify / Flow / Custom App）
git/
  .gitignore_global  # グローバル gitignore
zsh/
  .zshrc             # シェル設定（PATH / エイリアス / Claude Code ラッパー）
setup.sh             # シンボリックリンク作成スクリプト
```

## シンボリックリンク

`setup.sh` が以下のリンクを作成:

| リンク先 | リンク元 |
|---|---|
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/agents/` | `claude/agents/` |
| `~/.claude/commands/` | `claude/commands/` |
| `~/.claude/references/` | `claude/references/` |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.gitignore_global` | `git/.gitignore_global` |

## 別の PC との同期

```bash
cd ~/dotfiles && git pull
```

Claude Code 起動時に dotfiles を自動 pull するフックが `settings.json` に設定済み。
