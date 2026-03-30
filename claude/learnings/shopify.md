# Shopify Learnings
<!-- domain: shopify — テーマ・セクション・Liquid・Dawn・OS2.0 -->

## 2026-03-17 07:32 | god-suns_ver01
- 完了: コミット `a3d02e5` — `fix: label版ポインターが画像の下に隠れる問題を修正`

## 2026-03-25 03:46 | idol-anime.com
- [correction] 表示崩れはcss/jsを確認して修正 — PC/SP画像切替時のアスペクト比崩れを修正 `d6b0d21`

## 2026-03-26 | pietro-onlineshop_ver01
- [gotcha] ⚠️ 「カスタムインストール」は絶対に選ばない
- [pattern] ホバー色を揃えるには `base.css` の既存ルール (`.customer a:hover`) と同じ値を使う — `color: rgb(var(--color-link))` + `text-decoration-thickness: 0.2rem`

## 2026-03-25 | Pinup-Closet_ver01
- [gotcha] ⚠️ APIトークンは一度しか表示されない — 発行直後に必ずコピー
- [correction] 英語サイズ表記: `#Waist 100cm compatible` → `#Waist size 100cm or more`

## 2026-03-27 | Pionunnal_ver01
- [gotcha] Shopifyメール除外理由（バウンス履歴・ボット判定）はShopify内部フラグのため、エクスポートCSVには含まれない — 管理画面でのみ確認可能

## 2026-03-19 | dotfiles整備
- [gotcha] Shopifyテーマ（Webpack 4）: ビルドコマンド・Node Sass legacy・locales一括更新に注意

## 2026-03-27 | Shopify顧客CSVインポート
- [gotcha] メールアドレスのみの純正インポートは既存タグを上書きする
- [gotcha] CSVに重複がなくてもエラー「顧客が既にストアに存在する」が出ることがある → 既存顧客の更新には別手順が必要
