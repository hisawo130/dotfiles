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

## 2026-04-02 | P130
- 作業: claude exitのときに、学習を記録する機能動いてますか？

## 2026-04-02 | mimc.co.jp-mailmagazine
- 作業: # コーディング依頼
- 完了: `260410.html` を作成しました。
- [gotcha] PDFや画像内のテキストが読み取れない場合、推測で文章を作らず必ずユーザーに確認する。特にメール本文・商品説明文など正確さが重要なコンテンツは勝手に創作しない。
- [gotcha]    - `[gotcha]` — 罠・NG・禁止・バグ・エラーの原因

## 2026-04-02 | Pinup-Closet_ver01
- [correction] 以下修正してください
- [gotcha] (compoundコマンド禁止のフック)
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/Pinup-Closet_ver01/sections/cart-notification-product.liqui
- 注意点： localStorageに既に保存されている閲覧履歴には `productline` が含まれていないため、再訪問時に初めてラベルが保存されます。古い履歴はラベルなしで表示されます。
- 完了: [sections/main-product.liquid](sections/main-product.liquid#L259-L262) の `title` ブロック描画直前に追加しました。ブロック順序が `vendor → title` なので、実際の表示も vendor の直後にラベルが入り
- 完了: 全4ファイルに `| first` を追加しました。
- 完了: `width: fit-content` を追加しました。スクリーンショットのように文字幅に合ったタグ表示になります。
- 完了: PR作成しました: https://github.com/CIN-GROUP-EC/Pinup-Closet_ver01/pull/31

## 2026-04-02 | pietro-onlineshop_ver01
- 作業: クーポンコードURLです
- [pattern] 2. fetchが成功したかどうか確認していない
- 完了: 修正しました。fetchが成功（`res.ok`）した時だけ「適用済み」を記録するようにしました。失敗した場合は次のページ読み込み時に再試行されます。
- [correction] コードレビューを確認して修正してください
- [gotcha] ❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 19:38 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 19:42 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:04 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:14 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:18 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:18 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:19 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29
- 完了: 2点修正しました：

## 2026-04-02 20:22 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 20:23 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 20:31 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 20:32 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 20:33 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 20:34 | pietro-onlineshop_ver01
- 作業: https://github.com/CIN-GROUP-EC/pietro-onlineshop_ver01/pull/29

## 2026-04-02 21:01 | pietro-onlineshop_ver01
- 作業: /Users/P130/Desktop/26年3月誕生日ポイント.csv

## 2026-04-02 21:05 | pietro-onlineshop_ver01
- 作業: /Users/P130/Desktop/26年3月誕生日ポイント.csv

## 2026-04-02 21:50 | pietro-onlineshop_ver01
- 作業: /Users/P130/Desktop/26年3月誕生日ポイント.csv

## 2026-04-03 15:54 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 16:03 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 17:47 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 17:54 | pietro-onlineshop_ver01
- `.dd-button.click()` を廃止して `window.discountDeckInstance.showCoupons()` を直接呼び出した理由は、ポーリングで初期化を待つ実装に合わせるためです。

## 2026-04-03 17:55 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 17:57 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 17:57 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正

## 2026-04-03 17:58 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:05 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:06 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:07 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:07 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:08 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#30

## 2026-04-03 18:16 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#31

## 2026-04-03 18:21 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#31

## 2026-04-03 18:30 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#31

## 2026-04-03 18:50 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#31

## 2026-04-03 21:11 | pietro-onlineshop_ver01
- 作業: # チケット一覧モーダル 不具合修正
- 完了: PR作成しました: CIN-GROUP-EC/pietro-onlineshop_ver01#31
