# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## メール / HTML

- [tip] メルマガHTMLで `!important` は Outlook 回避用として有効
- [gotcha] PDFや画像内のテキストが読み取れない場合、推測で文章を作らず必ずユーザーに確認する。特にメール本文・商品説明文など正確さが重要なコンテンツは勝手に創作しない。

## JavaScript / フロントエンド

- [pattern] fetch成功判定は `res.ok` を必ず確認する。成功時だけ状態を記録し、失敗時は再試行できるようにする。
- [pattern] 非同期初期化待ち: `.dd-button.click()` のようなDOM依存呼び出しではなく `window.discountDeckInstance.showCoupons()` を直接呼び出す — ポーリングで初期化を待つ実装に合わせるため。
- [open] Rivyoが `DOMContentLoaded` より後にバッジを注入する場合は `MutationObserver` への変更が必要になる可能性がある（実装後に確認）。

## Git / dotfiles

- [pattern] save-learnings.sh の再帰防止: `CLAUDE_LEARNING_EXTRACT=1` 環境変数で自己呼び出しをガード
- [pattern] 追記専用ファイル（learningsログ等）のgitコンフリクト自動解消: `.gitattributes` に `claude/learnings/*.md merge=union` を設定する
- [pattern] dotfiles push前に `git pull --rebase` を実行して non-fast-forward エラーを防ぐ。learningsは `merge=union` で自動解消されるため手動マージ不要。

## MIMC / 案件固有

- [correction] `<div class="item_ttl">` は背景色ラベルになっている — デザインファイル(DF)に合わせること

## 2026-04-03 | dotfiles

- [tip] `/capture` スキルを使って重要な学びを手動で保存する運用の徹底
- [pattern] `pull --rebase` でコンフリクト → abort
- [tip] ルールベースなので「文脈的に重要」な学びは取れない

## 2026-04-02 | Pinup-Closet_ver01

- [tip] 注意点： localStorageに既に保存されている閲覧履歴には `productline` が含まれていないため、再訪問時に初めてラベルが保存されます。古い履歴はラベルなしで表示されます。

## Recurring Patterns (updated 2026-04-09)
- [shopify] インポートデータの列名・フォーマット厳格性: Matrixify列名差異・Line:Type必須・タグ上書き — seen 6 times
- [shopify] Liquidフィルター精度: divided_by整数除算・img_url廃止・リスト型メタフィールド出力 — seen 5 times
- [matrixify] MatrixifyはShopify純正CSVと列名形式が異なる（型サフィックス付き・Fulfillment Line必須） — seen 3 times
- [js] 非同期初期化待ちポーリング実装: windowフラグによるシングルトン化・名前空間付きイベント登録・DOM依存呼び出し回避 — seen 3 times

## 2026-04-06 | dotfiles [ai]

- [gotcha] Chrome DevTools MCPはデフォルトで使用統計をGoogleに送信（`--no-usage-statistics`で無効化必須）
- [pattern] Shopify/ecforceテーマ開発でビジュアル確認・JavaScriptデバッグをMCPで自動化できる
- [tip] Chrome DevToolsトレース取得によるパフォーマンス分析がエージェント実行時に活用可能

## 2026-04-06 19:49 | idol-anime.com [ai]
- [gotcha] Chrome を `--remote-debugging-port=9222` で起動していないと MCP が接続できない — CLI起動が必須
- [gotcha] 既存の Chrome セッションではなく新しいインスタンスで起動するのが確実。同時起動で動作不安定になりやすい
- [tip] `claude mcp list` で登録済みサーバーを確認してから使用。パッケージ名と MCP サーバー名が異なる場合がある

## 2026-04-10 10:33 | P130 [ai]
- [gotcha] ユニークコード1回限り有効の実装は、ランダム関数だけでは不十分。事前生成したコード一覧をDBで管理し、使用済みフラグで制御する必要がある。
- [pattern] 大規模キャンペーン（万単位の対象者）のLP・コード検証機能は、納期が短い場合（5月公開予定）、既存ECカートのテンプレートやノーコード施策で検討。完全カスタム構築は納期超過リスク。
- [gotcha] 年齢確認（アルコール飲料対応）の法的責任と実装方法（本人確認・配送時確認）を事前に確認。提携企業の責任分担も明確化すべき。

## 2026-04-10 12:18 | Pinup-Closet_ver01 [ai]
- [gotcha] 管理画面ページコンテンツのHTMLから参照する要素（data-remodal-target等）は、テーマ側で無条件レンダリングされているか確認必須。Liquid条件分岐で出力制限されていると該当ページに存在しない
- [pattern] product contextやページタイプに依存するモーダルは、複数ページから参照される可能性がある場合、条件を緩和するか汎用版を用意する
- [tip] Remodal実装時は、data-remodal-id と data-remodal-target の対応をテンプレートとJS両面から検証する
