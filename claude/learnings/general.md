# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## 2026-03-03 | HTML (MIMC メルマガ)
- メルマガHTMLで `!important` は Outlook 回避用として有効

## 2026-03-19 08:45 | GitHub (dotfiles整備)
- Shopifyテーマ（Webpack 4）: ビルドコマンド・Node Sass legacy注意・locales一括更新に注意
- ecforceテーマ: ec_force/構造、Shopify Liquidとの混同禁止

## 2026-03-23 05:55 | P130 (Claude Code設定)
- 作業: 外部サイトへのアクセスを自動承認化

## 2026-03-25 07:50 | HTML (MIMC 商品ページ)
- [ユーザー修正] `<div class="item_ttl">` などは背景色ラベルになっている — デザインファイル(DF)に合わせること

## 2026-03-26 04:04 | P130 (Shopifyアプリ)
- ⚠️ アプリ再インストール中はWebhookが中断される。既存トークン使用コードは新トークンへの差し替えが必要

## 2026-03-26 08:10 | P130 (Claude Code)
- `/review-pr` — 6エージェント並列でPRレビュー（Critical/Important/Suggestion/Strengths）
- 新規UI作成時: タイポグラフィはInter/Arial禁止

## 2026-03-26 10:14 | dotfiles
- Memory の読込・保存ルール未定義だったため CLAUDE.md に Memory protocol追加

## 2026-03-26 | dotfiles (save-learnings)
- save-learnings.sh の再帰防止: `CLAUDE_LEARNING_EXTRACT=1` 環境変数で自己呼び出しをガード

## 2026-03-27 04:53 | P130 (顧客CSVインポート)
- メールのまま純正インポートすると既存タグ上書きに注意
- CSVに重複がなくてもエラー「顧客が既にストアに存在する」が出ることがある → 既存顧客の更新には別手順が必要

## 2026-03-27 20:57 | P130
- 3. 手動で記録する → セッション後に重要な学びを `~/.claude/learnings/<domain>.md` に直接追記する
- | 常にゼロ（Credit balance too low） | 毎セッション必ず何か記録 |
- 1. 警告・重要パターン（`注意`, `罠`, `NG`, `必ず`…）
- [ユーザー修正] 自身のディレクトリツリーを見直してブラッシュアップして。自動駆動の軸は崩さないこと。
