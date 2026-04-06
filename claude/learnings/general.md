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
- [gotcha] WARNINGS — 注意・NG・罠系
- [tip] ルールベースなので「文脈的に重要」な学びは取れない
- [open] OPEN_ISSUES — 未解決・要調査

## 2026-04-02 19:26 | pietro-onlineshop_ver01
- 完了: 変更: [sections/page-lp-2026crispypizza.liquid](sections/page-lp-2026crispypizza.liquid), [templates/page.lp-202

- 完了: 修正しました。`Tags Command: DELETE` に更新済みです。同じファイル（`matrixify-customer-tags-bdp20260331-REMOVE.csv`）を再インポートしてください。

- [pattern] 2. fetchが成功したかどうか確認していない


- [correction] コードレビューを確認して修正してください
- [gotcha] ❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later

## 2026-04-02 13:45 | mimc.co.jp-mailmagazine
- - 500円OFFクーポンボックス（枠囲み、有効期限・注意事項付き）
- [correction] レイアウトや背景色がPDFと違うようです

- 完了: `260410.html` を作成しました。

- [gotcha]    - `[gotcha]` — 罠・NG・禁止・バグ・エラーの原因

## 2026-04-02 18:10 | Pinup-Closet_ver01
- [correction] ボタンの位置は改善されましたがアイコンがでなくなりました

- [correction] 以下修正してください

- [gotcha] (compoundコマンド禁止のフック)

- [tip] 注意点： localStorageに既に保存されている閲覧履歴には `productline` が含まれていないため、再訪問時に初めてラベルが保存されます。古い履歴はラベルなしで表示されます。

- 完了: [sections/main-product.liquid](sections/main-product.liquid#L259-L262) の `title` ブロック描画直前に追加しました。ブロック順序が `vendor → title` なので、実際の表示も vendor の直後にラベルが入り

- 完了: 全4ファイルに `| first` を追加しました。

- 完了: `width: fit-content` を追加しました。スクリーンショットのように文字幅に合ったタグ表示になります。

- 完了: PR作成しました: https://github.com/CIN-GROUP-EC/Pinup-Closet_ver01/pull/31

## Recurring Patterns (updated 2026-04-06)
- [shopify] インポートデータの列名・フォーマット厳格性: Matrixify列名差異・Line:Type必須・タグ上書き — seen 6 times
- [shopify] Liquidフィルター精度: divided_by整数除算・img_url廃止・リスト型メタフィールド出力 — seen 5 times
- [matrixify] MatrixifyはShopify純正CSVと列名形式が異なる（型サフィックス付き・Fulfillment Line必須） — seen 3 times
- [js] 非同期初期化待ちポーリング実装: windowフラグによるシングルトン化・名前空間付きイベント登録・DOM依存呼び出し回避 — seen 3 times

## 2026-04-04 11:41 | dotfiles
- [correction] ついでに全部見直しておいて

## 2026-04-06 19:42 | dotfiles [ai]
- [gotcha] Chrome DevTools MCPはデフォルトで使用統計をGoogleに送信（`--no-usage-statistics`で無効化必須）
- [pattern] Shopify/ecforceテーマ開発でビジュアル確認・JavaScriptデバッグをMCPで自動化できる
- [tip] Chrome DevToolsトレース取得によるパフォーマンス分析がエージェント実行時に活用可能
