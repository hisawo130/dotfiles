# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## 2026-03-03 | HTML (MIMC メルマガ)
- [tip] メルマガHTMLで `!important` は Outlook 回避用として有効

## 2026-03-25 | HTML (MIMC 商品ページ)
- [correction] `<div class="item_ttl">` は背景色ラベルになっている — デザインファイル(DF)に合わせること

## 2026-03-26 | dotfiles (save-learnings)
- [pattern] save-learnings.sh の再帰防止: `CLAUDE_LEARNING_EXTRACT=1` 環境変数で自己呼び出しをガード

## 2026-03-30 | pietro-onlineshop_ver01
- 完了: 変更: [sections/page-lp-2026crispypizza.liquid](sections/page-lp-2026crispypizza.liquid), [templates/page.lp-202

## 2026-03-30 | mimc.co.jp-mailmagazine
- - 500円OFFクーポンボックス（枠囲み、有効期限・注意事項付き）
- [correction] レイアウトや背景色がPDFと違うようです

## 2026-03-31 | pietro-onlineshop_ver01
- 作業: matrixifyの依頼です
- 完了: 作成しました。
- 完了: 完了しました。
- 完了: 修正しました。`Tags Command: DELETE` に更新済みです。同じファイル（`matrixify-customer-tags-bdp20260331-REMOVE.csv`）を再インポートしてください。
- 作業: このセッションに移動したいです

## 2026-03-31 | Pinup-Closet_ver01
- [open] 注意点: Rivyoが `DOMContentLoaded` より後にバッジを注入する場合は `MutationObserver` への変更が必要になる可能性があります（実装後に確認）。
- 完了: 実装完了しました。
- 完了: プッシュ完了しました。
- [correction] ボタンの位置は改善されましたがアイコンがでなくなりました
- 完了: PRを作成しました。

## Recurring Patterns (updated 2026-04-01)
- [shopify] ShopifyのCSVインポート・エクスポートには仕様上の落とし穴が多い（タグ上書き・重複エラー・Matrixify列名差異） — seen 6 times
- [matrixify] MatrixifyはShopify純正CSVと列名形式が異なる（型サフィックス付き・Fulfillment Line必須） — seen 3 times

## 2026-04-02 13:10 | P130
- 作業: claude exitのときに、学習を記録する機能動いてますか？

## 2026-04-02 13:22 | mimc.co.jp-mailmagazine
- 作業: # コーディング依頼
- 完了: `260410.html` を作成しました。

## 2026-04-02 | mimc.co.jp-mailmagazine
- [gotcha] PDFや画像内のテキストが読み取れない場合、推測で文章を作らず必ずユーザーに確認する。特にメール本文・商品説明文など正確さが重要なコンテンツは勝手に創作しない。

## 2026-04-02 13:45 | mimc.co.jp-mailmagazine
- [gotcha]    - `[gotcha]` — 罠・NG・禁止・バグ・エラーの原因

## 2026-04-02 13:48 | Pinup-Closet_ver01
- [correction] 以下修正してください

## 2026-04-02 13:50 | Pinup-Closet_ver01
- [gotcha] (compoundコマンド禁止のフック)

## 2026-04-02 16:59 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui

## 2026-04-02 17:01 | _frontend
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 完了しました。

## 2026-04-02 17:02 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 完了しました。

## 2026-04-02 17:04 | Pinup-Closet_ver01
- 注意点： localStorageに既に保存されている閲覧履歴には `productline` が含まれていないため、再訪問時に初めてラベルが保存されます。古い履歴はラベルなしで表示されます。

## 2026-04-02 17:06 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: [sections/main-product.liquid](sections/main-product.liquid#L259-L262) の `title` ブロック描画直前に追加しました。ブロック順序が `vendor → title` なので、実際の表示も vendor の直後にラベルが入り

## 2026-04-02 17:13 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 全4ファイルに `| first` を追加しました。

## 2026-04-02 17:15 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 全4ファイルに `| first` を追加しました。

## 2026-04-02 17:16 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 全4ファイルに `| first` を追加しました。

## 2026-04-02 17:17 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: 全4ファイルに `| first` を追加しました。

## 2026-04-02 17:19 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: `width: fit-content` を追加しました。スクリーンショットのように文字幅に合ったタグ表示になります。

## 2026-04-02 17:27 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: `width: fit-content` を追加しました。スクリーンショットのように文字幅に合ったタグ表示になります。

## 2026-04-02 17:31 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: `width: fit-content` を追加しました。スクリーンショットのように文字幅に合ったタグ表示になります。

## 2026-04-02 18:10 | Pinup-Closet_ver01
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 完了: PR作成しました: https://github.com/CIN-GROUP-EC/Pinup-Closet_ver01/pull/31

## 2026-04-02 18:31 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:33 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:34 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:35 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:37 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:39 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです

## 2026-04-02 18:40 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです
