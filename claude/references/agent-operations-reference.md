# Agent Operations Reference (On-demand)

このファイルは、`claude/CLAUDE.md` の常時実行ルールから切り離した参照情報です。
必要なタスク時だけ読み込む前提です。

## SessionStart hooks (自動実行順)

| 順序 | フック | 動作 |
|---|---|---|
| 1 | `check-stale-refs.sh` | 14日以上未更新のリファレンスファイルを警告 |
| 2 | `recovery-detect.sh` | 前回クラッシュ検出 — state.md + clean marker で判定 |
| 3 | `stale-branch-check.sh` | origin/main より 1 commit でも遅れていたら fast-forward pull。不可なら警告のみ |
| 4 | `shopify-session-start.sh` | Shopifyリポジトリのみ: git pull + Shopify CLI 認証確認 |
| 5 | `ecforce-session-start.sh` | ecforceリポジトリのみ: git pull + 本番テーマ編集リマインダー |
| 6 | `load-learnings.sh` | ドメイン別学習メモを systemMessage に注入 |

## カスタムコマンド（学習/運用系）

| コマンド | 用途 |
|---|---|
| `/capture [domain] <insight>` | 学習メモを手動で即時保存（Stop hook を待たず） |
| `/learning-report` | 主要ドメインの学習サマリーをレポート表示 |
| `/memory-update` | 現セッションの学習を `claude/memory/` に即時統合 |
| `/nightly-review` | 夜間自己改善バッチ（6タスク + 週次タスク）を手動実行 |
| `/sync-dotfiles` | `claude/` 配下の変更をコミット・プッシュ |

## Injected learnings (from SessionStart hook)

On session start, `📚 前回の学習メモ` may appear in context from `load-learnings.sh`.

- `[recurring]` — confirmed trap seen 3+ times; treat as an invariant rule
- `[gotcha]` — confirmed trap; check against current plan before implementing
- `[correction]` — previous mistake; verify you are not repeating it
- `[pattern]` — a known-good approach; prefer it over alternative implementations

## Default assumptions

When not explicitly specified, assume:

- **Shopify:** Dawn (latest stable), Online Store 2.0, no app dependencies
- **ecforce:** Liquid templates, file uploader for assets, `{{ file_root_path }}` for asset URL base
- **CSS:** Follow existing class names and design patterns
- **JS:** Vanilla JS or match the existing framework in use

## Platform-specific notes

### Shopify

- Theme: specify Dawn version or custom theme name
- Always use section schema `{% schema %}` for customizer settings
- Asset references: `{{ 'filename.css' | asset_url | stylesheet_tag }}`
- Test on both desktop and mobile preview in theme editor
- Check for impact on other sections that share the same CSS namespace

**Common traps (auto-check before finishing):**
- `settings_data.json` accidentally staged → warn and unstage
- `{% include %}` used instead of `{% render %}` → replace automatically
- Schema setting IDs changed/removed → flag as breaking change
- Hardcoded domain or asset URL → replace with Liquid filter

### ecforce

- Template engine: **Liquid** (`.html.liquid`、スマホ版は `+smartphone` サフィックス)
- Layouts: `layouts/ec_force/shop/order.html.liquid`（購入フロー）/ `layouts/ec_force/shop.html.liquid`（その他）
- Partials: `{% include 'ec_force/shop/shared/header.html' %}` 形式
- Assets: 管理画面のファイルアップローダー。参照は `{{ file_root_path }}/css/style.css`
- **保存 = 即本番反映**（現在のテーマ直接編集時）。必ずテーマを複製してから編集 → プレビュー確認 → テーマ切り替えの順で行う
- ローカル環境での開発不可（Liquidはサーバーサイドレンダリングのみ）
- デフォルトCSSに `!important` 多用 → CSS詳細度競合に注意
- 新規URLルート追加・フォーム項目変更・サーバーサイド処理変更は不可
- Check order flow pages (cart → order input → confirm → complete) for side effects

**Common traps (auto-check before finishing):**
- Editing active theme directly → always duplicate first; flag if can't confirm
- Hardcoded asset URL (not using `{{ file_root_path }}`) → replace automatically
- Missing `+smartphone` variant when desktop template changed → flag for manual check
- CSS `!important` added → note specificity risk in response

## NotebookLM integration

NotebookLM CLI (`nlm`) and MCP server are available for research and persistent memory.

**Master Brain notebook ID:** `58f81c6c-6f3e-42d1-9de5-e59b8975f51c`

**Environment check (runs automatically at SessionStart):**
- `🧠 NotebookLM: 接続済み` → nlm available
- `🧠 NotebookLM: nlm未インストール` → Web/CI environment; skip nlm commands
- `🧠 NotebookLM: 未認証` → run `nlm login` first

Before answering architecture/history questions, if nlm is available:

```bash
nlm notebook query 58f81c6c-6f3e-42d1-9de5-e59b8975f51c "<question>"
```

## Nightly self-improvement

Every day at AM3:00 JST, `nightly-self-improve.sh` (local cron) and `.github/workflows/nightly-self-improve.yml` run:

| Step | Tool | Description |
|---|---|---|
| preprocess | `nightly-preprocess.py` | Stale dates, metrics, gotcha候補, growth-log scaffold |
| shell-validate | `nightly-validate-shell.py` | bash -n + shellcheck for hooks/scripts |
| postprocess | `nightly-postprocess.py` | Fill growth-log placeholders |
| AI review | `nightly-review.md` + `claude -p` | Memory consolidation, CLAUDE.md review |
| Master Brain | `nlm source add` (local only) | Push growth-log entry to NotebookLM |
