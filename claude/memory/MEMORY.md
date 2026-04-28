# Memory Index

## User
- [user_profile.md](user_profile.md) — Role, platforms (Shopify + ecforce Liquid), language, working style

## Feedback
- [feedback_autonomy.md](feedback_autonomy.md) — Proceed without confirmation on all non-destructive actions
- [feedback_ecforce_platform.md](feedback_ecforce_platform.md) — ecforce uses Liquid (not ERB/Slim); system-reminder can show stale CLAUDE.md
- [feedback_reference_update_before_use.md](feedback_reference_update_before_use.md) — UPDATE BEFORE USEコメントがあるリファレンスは参照前にWebFetchで最新化する
- [feedback_platform_routing.md](feedback_platform_routing.md) — ecforce/Shopify参照を絶対に混在させない。記法差異チェックリスト付き
- [feedback_matrixify_docs.md](feedback_matrixify_docs.md) — Matrixifyタスク開始前に必ず公式ドキュメントをWebFetchで取得すること
- [feedback_autorun_tests.md](feedback_autorun_tests.md) — テスト実行・テスト結果に基づく改修は承認不要で自動実行
- [feedback_empirical_prompt_tuning.md](feedback_empirical_prompt_tuning.md) — スキル改善はバイアスフリーサブエージェントで実行評価。1テーマずつ修正、tool_uses偏差で自己完結度チェック

## Project
- [project_browser_mcp.md](project_browser_mcp.md) — browser MCP選定: 現在は@playwright/mcp、移行候補はbrowser-use CLI

## Reference

**dotfiles管理 (`~/.claude/references/`):**
- `shopify-dawn-reference.md` — Dawn v15.4.1完全リファレンス（ディレクトリ構成・CSS変数体系・Custom Elements・全sections/snippets一覧・カスタマイズBP）
- `shopify-reference.md` — Shopifyテーマ総合（Dawn・OS2.0・API）
- `shopify-custom-app-reference.md` — カスタムアプリ（Storefront API・Functions・GraphQL）
- `shopify-flow-reference.md` — Shopify Flow
- `shopify-theme-app-extensions-reference.md` — Theme App/Embed Extensions・Customer Account UI Extensions
- `shopify-webhooks-metafields-reference.md` — Webhooks・Metafields/Metaobjects
- `shopify-hydrogen-appbridge-subscriptions-reference.md` — Hydrogen・App Bridge・Selling Plans・B2B
- `ecforce-reference.md` — ecforceフロントエンド完全技術リファレンス

**セッション学びログ（ドメイン別・自動蓄積）:**
- ドメイン: `shopify` / `shopify-app` / `shopify-flow` / `shopify-extensions` / `shopify-hydrogen` / `shopify-webhooks` / `ecforce` / `wordpress` / `ec-cube` / `matrixify` / `ga4-gtm` / `klaviyo` / `line` / `react-nextjs` / `vue-nuxt` / `github-actions` / `cloudflare` / `make-zapier` / `cms` / `stripe` / `general`
- Stop hookが毎セッション終了時にドメインを自動判定して追記。auto-context時に該当ドメインのみ末尾60行をロード
- セカンダリドメイン対応: 1セッションで複数ドメインに同時書き込み（例: shopify + matrixify）
- `[recurring]` 自動昇格: `[gotcha]` が3回出現すると Recurring Patterns セクションに自動昇格

**成長ログ:**
- [growth-log.md](../scripts/growth-log.md) — 夜間バッチの実行記録・ドメイン別メトリクス（AM3:00 JST 自動追記）

**カスタムコマンド（`/` で起動）:**
- `/capture [domain] <insight>` — 学習メモを手動で即時保存（Stop hookを待たず）
- `/learning-report` — 全21ドメインの学習サマリーレポートを生成（エントリ数・gotcha/recurring集計）
- `/memory-update` — セッション中の学習を即時保存（夜間バッチ待ち不要）
- `/nightly-review` — 夜間自己改善バッチを手動トリガー
- `/sync-dotfiles` — `claude/` 配下の変更をコミット・プッシュ

**エージェント（`~/.claude/agents/`）:**
- `researcher` — ファイル読み込み・Web調査・パターン検索（Haiku: 高速）
- `planner` — アーキテクチャ設計・複数ファイル計画（Sonnet）
- `executor` — 実装・編集・テスト・デバッグ・git操作（Sonnet）
- `reviewer` — 実装後レビュー: PASS/FAIL判定のみ（Sonnet）
- `learning-consolidator` — セッション学習をメモリファイルへ統合（夜間バッチTASK 1）

**メモリ固有（dotfilesに含めない補助情報）:**
- [reference_ecforce_consolidated.md](reference_ecforce_consolidated.md) — ecforce技術リファレンスポインタ → `~/.claude/references/ecforce-reference.md`
- [reference_matrixify.md](reference_matrixify.md) — Shopify Matrixify機能・仕様・落とし穴
- [shopify_theme_architecture.md](shopify_theme_architecture.md) — DawnバージョンHistory・Theme Blocks・Sectionスキーマ
- [shopify_platform_updates.md](shopify_platform_updates.md) — Shopify廃止スケジュール・Winter '26新機能
- [shopify_performance.md](shopify_performance.md) — Core Web Vitals対策・LCP最適化
