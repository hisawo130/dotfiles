# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## 2026-03-03 | HTML (MIMC メルマガ)
- [tip] メルマガHTMLで `!important` は Outlook 回避用として有効

## 2026-03-19 | dotfiles整備
- [gotcha] Shopifyテーマ（Webpack 4）: ビルドコマンド・Node Sass legacy・locales一括更新に注意
- [gotcha] ecforceテーマ: ec_force/構造はShopify Liquidと記法が異なる — 混同禁止

## 2026-03-25 | HTML (MIMC 商品ページ)
- [correction] `<div class="item_ttl">` は背景色ラベルになっている — デザインファイル(DF)に合わせること

## 2026-03-26 | Shopifyアプリ
- [gotcha] ⚠️ アプリ再インストール中はWebhookが中断される。既存トークン使用コードは新トークンへの差し替えが必要

## 2026-03-26 | dotfiles (save-learnings)
- [pattern] save-learnings.sh の再帰防止: `CLAUDE_LEARNING_EXTRACT=1` 環境変数で自己呼び出しをガード

## 2026-03-27 | Shopify顧客CSVインポート
- [gotcha] メールアドレスのみの純正インポートは既存タグを上書きする
- [gotcha] CSVに重複がなくてもエラー「顧客が既にストアに存在する」が出ることがある → 既存顧客の更新には別手順が必要
