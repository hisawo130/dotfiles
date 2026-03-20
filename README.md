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
  commands/          # スラッシュコマンド一覧（下表参照）
  references/        # プラットフォームリファレンス（Shopify / Flow / Custom App）
git/
  .gitignore_global  # グローバル gitignore
zsh/
  .zshrc             # シェル設定（PATH / エイリアス / Claude Code ラッパー）
setup.sh             # シンボリックリンク作成スクリプト
```

## スラッシュコマンド一覧

| コマンド | 説明 |
|---|---|
| `/shopify-pr` | Shopify テーマのPR作成（テーマバージョン自動検出・検証付き） |
| `/shopify-push` | テーマをストアへpush（theme check自動実行） |
| `/shopify-section <name>` | Dawn OS2.0準拠のセクションをスキャフォールド |
| `/snippet-scaffold <name>` | Dawn準拠のスニペットをスキャフォールド |
| `/theme-check` | Shopify theme check実行（一部エラー自動修正） |
| `/ecforce-pr` | ecforceテーマのPR作成（購入フロー影響度スコア付き） |
| `/ecforce-checklist` | ecforceデプロイ前チェックリスト |
| `/git-checkpoint` | WIPチェックポイントコミット作成 |
| `/post-review` | 実装後レビュー（インタラクティブ） |
| `/context-load` | プロジェクト種別検出＋リファレンス自動ロード |
| `/debug-liquid` | Liquidテンプレートの変数・出力デバッグ |
| `/sync-refs` | 全リファレンスドキュメントを一括更新 |

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

## Git エイリアス（.zshrc）

| エイリアス | コマンド |
|---|---|
| `gs` | `git status` |
| `gl` | `git log --oneline -20` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `glog` | `git log --oneline --graph --all -30` |


## リモートコントロール（ヘッドレス実行）

Claude Code を非インタラクティブに実行するためのラッパーが付属しています。

### インストール後の使い方

```bash
# シンプル実行
claude-run "テーマのスニペット一覧を出力して"

# 作業ディレクトリ指定
claude-run --dir ~/projects/my-theme "未使用の CSS クラスを探して"

# JSON 出力（CI/パース用）
claude-run --json "セキュリティ問題を報告"

# ツール制限（読み取り専用）
claude-run --tools "Read,Grep,Glob" "全 Liquid テンプレートをスキャン"

# ターン数制限
claude-run --turns 5 "Shopify Section のスキーマを列挙"
```

### CI / GitHub Actions

`claude/templates/claude.yml` を `.github/workflows/` にコピーして使用:

```bash
cp claude/templates/claude.yml .github/workflows/
```

GitHub リポジトリの Secrets に `ANTHROPIC_API_KEY` を設定してください。

### SSH リモート実行

```bash
# コードが存在するサーバーで直接実行
ssh myserver "cd /srv/shopify-theme && \
  claude -p 'テーマ監査を実行して結果を報告' \
    --dangerously-skip-permissions --output-format json"
```

> 詳細: `/headless` コマンド (`claude/commands/headless.md`)
