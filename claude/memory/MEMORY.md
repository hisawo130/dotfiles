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

**メモリ固有（dotfilesに含めない補助情報）:**
- [reference_matrixify.md](reference_matrixify.md) — Shopify Matrixify機能・仕様・落とし穴
- [shopify_theme_architecture.md](shopify_theme_architecture.md) — DawnバージョンHistory・Theme Blocks・Sectionスキーマ
- [shopify_platform_updates.md](shopify_platform_updates.md) — Shopify廃止スケジュール・Winter '26新機能
- [shopify_performance.md](shopify_performance.md) — Core Web Vitals対策・LCP最適化
