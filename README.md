# dotfiles

macOS 開発環境の設定ファイル。Claude Code / Shopify / ecforce 開発に最適化。

## 5分スタート（大規模コードベース向け）

1. **目的を1つに絞る**（1セッション1タスク）
2. **読み取り中心で開始**（例: `Read/Grep/Glob`）
3. **検証コマンドを先に実行**（下記「検証」参照）
4. **必要になったら権限を段階的に拡張**（read/search → write → git）

```bash
# 安全デフォルト（危険モードなし）
claude-run --tools "Read,Grep,Glob" "対象ディレクトリの構成と変更影響を調査して"

# 危険モードが必要な場合のみ明示的に opt-in
claude-run --dangerous "変更を適用して検証して"
```

> `scripts/claude-run.sh` はデフォルトで safe 実行です。`--dangerous` 指定時のみ `--dangerously-skip-permissions` を有効化します。

## セットアップ

```bash
git clone https://github.com/hisawo130/dotfiles.git ~/dotfiles
bash ~/dotfiles/setup.sh
```

> 任意のパス（例: `~/GitHub/dotfiles`）にも対応。`setup.sh` 実行時に `~/.dotfiles-root` へ実体パスを記録し、各 hook / scripts / zshrc がそこから解決します。

## 構成

```
claude/
  CLAUDE.md          # グローバル指示（システムプロンプト）
  settings.json      # 権限・フック・effortLevel
  agents/            # サブエージェント定義（planner / executor / researcher / reviewer 他）
  commands/          # スラッシュコマンド（旧形式、後方互換で動作）
  skills/            # スキル一覧（下表参照）
  hooks/             # SessionStart / PreToolUse / PostToolUse / Stop hook 群
    lib/             # フック共通ライブラリ（dotfiles-root 解決・ドメイン判定）
  learnings/         # ドメイン別学習ログ（自動蓄積）
  memory/            # 永続メモ（feedback/project/reference/user）
  references/        # プラットフォームリファレンス（Shopify / ecforce）
  scripts/prompts/   # 夜間バッチ用プロンプト（nightly-review.md / daily-maintenance.md）
  templates/         # CI / GitHub Actions 用テンプレート
  tools/             # Pythonユーティリティ（git-ops / multi-edit / bulk-read 他）
git/
  .gitignore_global  # グローバル gitignore
zsh/
  .zshrc             # シェル設定（PATH / エイリアス / Claude Code ラッパー）
scripts/
  claude-run.sh             # ヘッドレス実行ラッパー
  install-nightly-cron.sh   # 夜間バッチ cron 登録
  nightly-self-improve.sh   # 夜間自己改善バッチ本体（Python only、AM3:00 JST）
  nightly-preprocess.py     # learnings digest 生成
  nightly-validate-shell.py # シェルスクリプト構文検証
  nightly-postprocess.py    # growth-log placeholder 埋め
setup.sh             # シンボリックリンク作成スクリプト
```

## スキル・コマンド一覧

### スキル（`claude/skills/`）

| コマンド | 説明 |
|---|---|
| `/skill-creator [name]` | 対話形式でカスタムスキル（SKILL.md）を生成・保存 |

### コマンド（`claude/commands/`）

| コマンド | 説明 |
|---|---|
| `/shopify-pr` | Shopify テーマのPR作成（テーマバージョン自動検出・検証付き） |
| `/shopify-push` | テーマをストアへpush（theme check自動実行） |
| `/shopify-section <name>` | Dawn OS2.0準拠のセクションをスキャフォールド |
| `/snippet-scaffold <name>` | Dawn準拠のスニペットをスキャフォールド |
| `/theme-check` | Shopify theme check実行（一部エラー自動修正） |
| `/ecforce-pr` | ecforceテーマのPR作成（購入フロー影響度スコア付き） |
| `/ecforce-checklist` | ecforceデプロイ前チェックリスト |
| `/ecforce-deploy` | ecforceテーマのデプロイ |
| `/feature-dev` | フィーチャーブランチ作成＋実装フロー |
| `/git-checkpoint` | WIPチェックポイントコミット作成 |
| `/review-pr` | PRレビュー支援 |
| `/post-review` | 実装後レビュー（インタラクティブ） |
| `/context-load` | プロジェクト種別検出＋リファレンス自動ロード |
| `/debug-liquid` | Liquidテンプレートの変数・出力デバッグ |
| `/frontend-design` | フロントエンドデザイン実装支援 |
| `/sync-refs` | 全リファレンスドキュメントを一括更新 |
| `/sync-dotfiles` | dotfiles を手動同期 |
| `/nightly-review` | 夜間自己改善バッチを手動実行 |
| `/wrap-up` | セッション終了時の知見整理＋Master Brainへpush |
| `/state` | プロジェクト状態の保存・読み込み |
| `/status-env` | 環境ステータス確認 |
| `/memory-update` | メモリファイルの手動更新 |
| `/learning-report` | 学習ログレポート生成 |
| `/capture` | セッションの学びを手動キャプチャ |
| `/doctor` | dotfiles 健全性チェック |
| `/cleanup-perms` | settings.local.json の不要権限を削除 |
| `/empty-trash` | ゴミ箱を空にする |
| `/headless` | ヘッドレス実行のガイド |

## シンボリックリンク

`setup.sh` が以下のリンクを作成:

| リンク先 | リンク元 |
|---|---|
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/agents/` | `claude/agents/` |
| `~/.claude/commands/` | `claude/commands/` |
| `~/.claude/hooks/` | `claude/hooks/` |
| `~/.claude/tools/` | `claude/tools/` |
| `~/.claude/references/` | `claude/references/` |
| `~/.claude/learnings/` | `claude/learnings/` |
| `~/.claude/memory/` | `claude/memory/` |
| `~/.claude/skills/<name>/` | `claude/skills/<name>/`（各スキルを個別symlink） |
| `~/.claude/logs/` | (mkdir) |
| `~/.local/bin/claude-scripts` | `scripts/` |
| `~/.local/bin/claude-run` | `scripts/claude-run.sh` |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.gitignore_global` | `git/.gitignore_global` |
| `~/.dotfiles-root` | (text file: dotfiles 実体パス) |

## NotebookLM 統合

`nlm` CLI（`notebooklm-mcp-cli`）と連携して、セッション知見を永続メモリに保存:

```bash
# セットアップ（初回のみ）
uv tool install notebooklm-mcp-cli
nlm setup add claude-code   # Claude Code MCP に登録
nlm login                    # Google 認証
nlm skill install claude-code  # nlm-skill インストール
```

| ノートブック | 用途 |
|---|---|
| Master Brain (`58f81c6c-...`) | セッション知見の永続メモリ |

- セッション終了時に `[gotcha]/[correction]/[recurring]` エントリを自動 push（`save-learnings.sh`）
- `/wrap-up` コマンドで手動サマリーを push
- `nlm` 未インストール環境では自動スキップ（複数PC同期に影響なし）

## 夜間自己改善パイプライン

毎日 AM3:00 JST（月〜金）にローカル cron と GitHub Actions が自動実行:

| Step | ツール | 内容 |
|---|---|---|
| preprocess | `nightly-preprocess.py` | stale dates 修正・メトリクス・growth-log scaffold |
| shell-validate | `nightly-validate-shell.py` | bash -n + shellcheck |
| postprocess | `nightly-postprocess.py` | growth-log placeholder 埋め |
| Master Brain sync | `nlm source add`（ローカルのみ） | growth-log エントリを NotebookLM へ push |

> Claude API は使用しない（Pro 制限に影響ゼロ）。

## 権限の段階導入（Trust Ramp-up）

- **Phase 1（初期）**: `Read/Grep/Glob` と検証系コマンドのみでコードベース理解を優先
- **Phase 2（編集）**: 変更範囲を限定して `Write/Edit` を許可
- **Phase 3（統合）**: 検証手順が安定した後に `git` / `gh` を段階開放
- 常時フル許可ではなく、タスクに必要な最小権限で運用する

## 検証（完了条件）

- シェル系変更: `python3 /home/runner/work/dotfiles/dotfiles/scripts/nightly-validate-shell.py`
- 夜間パイプライン変更: `python3 /home/runner/work/dotfiles/dotfiles/scripts/nightly-preprocess.py` と `python3 /home/runner/work/dotfiles/dotfiles/scripts/nightly-postprocess.py <digest.json> <shell.json>`
- GitHub Actions（`nightly-self-improve`）完了条件:
  - preprocess / shell-validate / postprocess がすべて exit 0
  - shell-validate の `checked > 0`
  - shell-validate の `syntax_errors == 0`

```bash
# cron 登録
bash ~/dotfiles/scripts/install-nightly-cron.sh

# 手動実行
/nightly-review
```

## 別の PC との同期

```bash
cd "$(head -1 ~/.dotfiles-root)" && git pull
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
