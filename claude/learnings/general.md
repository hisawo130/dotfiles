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

## 2026-04-10 12:21 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで条件付き出力されるコンポーネント（モーダル、スニペット等）は、参照元が複数ページタイプにまたがる場合、すべてのコンテキストで出力されるか条件を見直す必要がある
- [pattern] モーダル不表示の調査は、ボタンの`data-remodal-target`値から逆引きして対応する`data-remodal-id`のHTML定義を探すことから始める
- [correction] 新しいモーダルを追加する前に、対象商品が既存のモーダルをどう参照しているか確認し、一貫性を保つべき

## 2026-04-10 12:23 | Pinup-Closet_ver01
- 作業: 以下ページのマイサイズを見つけるの挙動が変です。本当はチャート式になっているはずなので確認してください。
- 完了: 追加しました。ただし、これはJSのオーバーライドです。**`modal-sylphide` のHTMLモーダル本体がpage.content（Shopify管理画面のページ本文）に存在しているか**が前提になります。

## 2026-04-10 12:23 | Pinup-Closet_ver01

## 2026-04-10 12:23 | Pinup-Closet_ver01
- [correction] 具体的には条件を変更します。修正してよいですか？

## 2026-04-10 12:23 | Pinup-Closet_ver01 [ai]
- [gotcha] LPページはproduct contextを持たないため、`if product.id == ...` で条件分岐されたモーダルHTMLは出力されない。汎用モーダルはページ本文またはテンプレート上部に無条件で配置する必要がある
- [pattern] Shopify管理画面のページコンテンツに定義されたモーダル（`data-remodal-id`）に対して、テーマのJS側でクリックハンドラをオーバーライドすることで機能追加できる（Sireneの例参照）
- [tip] モーダルが動作しない場合、`data-remodal-target` 値がHTMLに存在するか確認する際、ページコンテンツ（Shopify管理画面）とテンプレート両方をチェックが必須

## 2026-04-10 12:23 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで `data-remodal-target` を使う場合、モーダルのHTML本体が `page.content`（管理画面ページ本文）内に定義されているか、テーマファイル内に定義されているか必ず確認する。テーマファイルだけでは完全な構造は見えない。
- [pattern] Shopifyテーマで同一コンポーネント（モーダル等）が複数LPで使われる場合、JSオーバーライドで動作をページごとにカスタマイズするアプローチ（Sireneの事例）が保守性が高い。Liquid条件分岐より柔軟。
- [tip] Shopifyテーマのモーダル実装確認はブラウザDevToolsで `data-remodal-id` 属性の有無を検査するのが最短。テーマファイルと管理画面を行き来するより効率的。

## 2026-04-10 12:26 | Pinup-Closet_ver01

## 2026-04-10 12:26 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopify LP ページではproduct contextがないため、layout/theme.liquid の商品ID条件分岐（`if product.id == ...`）内で定義されたモーダルは表示されない。LP用モーダルは条件を変更するか別途定義が必要。
- [pattern] Shopify LPページでモーダル機能を実装する場合、Sireneパターン（page.contentにHTMLを直書き + ページテンプレートでJSオーバーライド）を踏襲。modal-sireneのように `data-remodal-id` でページ本文に定義し、ページテンプレート側でイベントハンドラを追加。
- [tip] モーダル問題が複数ある場合、ブラウザデベロッパーツールで実際にレンダリングされているHTMLを確認し、page.content内のモーダル定義状況を把握してから修正。テーマファイルだけでは管理画面コンテンツ確認不可。

## 2026-04-10 12:50 | Pinup-Closet_ver01
- 重要な発見です。興味深い矛盾点があります：
- 重要な発見です。チャンクサイズが5000文字では複数モーダルをまたいで読んでしまっています。モーダルの出現順序を確認します。
- [gotcha] 重要なバグを発見しました：

## 2026-04-10 12:50 | Pinup-Closet_ver01 [ai]
- [gotcha] page.content（Shopify管理画面で編集するページ本文）に埋め込まれたHTMLはテーマテンプレート分析では見えない。モーダルIDとボタンターゲットのペアリング検証にはブラウザ検査が必須。
- [gotcha] 条件付きレンダリング（`if product.id == ...`）でモーダルを出力すると、そのコンテキストにない場所（LP等）ではHTML本体が存在しない。ボタンのみ存在する矛盾状態になる。
- [pattern] LP固有UI実装パターン：モーダルHTMLはpage.contentに定義、JSハンドラはpage.lp-corset*.liquidで層分離する。ブランド追加時、LiquidはLP条件のみ、JSハンドラを足すだけで拡張可能。

## 2026-04-10 12:53 | Pinup-Closet_ver01
- 完了: PRが必要な場合は、mainを1コミット戻してブランチから再PRする形になりますが、**既にmainにマージ済み**の状態なので、このままShopifyにpushする方が早いです。どうしますか？

## 2026-04-10 12:53 | Pinup-Closet_ver01
- - [gotcha] 商品ページ向けに`if product.id == ...`条件でモーダルHTMLをレンダリングすると、product contextを持たないLPページでは出力されない。複数ページタイプで使うモーダルは条件設計に注意。

## 2026-04-10 12:53 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマでpage.contentに埋め込まれたHTMLモーダルはテーマファイルには見えない。ブラウザのデベロッパーツールで実際に`data-remodal-id`が存在するか確認が必須。
- [gotcha] 商品ページ向けに`if product.id == ...`条件でモーダルHTMLをレンダリングすると、product contextを持たないLPページでは出力されない。複数ページタイプで使うモーダルは条件設計に注意。
- [pattern] Shopifyテーマで複数ブランド向けモーダルを実装する場合、LiquidファイルのJSオーバーライド箇所で各ブランドID毎のハンドラを定義し、page.content側で共通のdata-remodal-idを指定する構造が統一的。

## 2026-04-10 12:55 | Pinup-Closet_ver01
- [correction] 修正してください。
