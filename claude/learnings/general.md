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

## 2026-04-03 21:26 | dotfiles
- - `/capture` スキルを使って重要な学びを手動で保存する運用の徹底
- [pattern] - リモートに先行コミットがあったため non-fast-forward エラー
- [pattern] - `pull --rebase` でコンフリクト → abort

## 2026-04-03 21:30 | dotfiles

## 2026-04-03 21:35 | dotfiles

## 2026-04-03 21:36 | dotfiles

## 2026-04-03 21:38 | dotfiles
- [gotcha] - `WARNINGS` — 注意・NG・罠系
- - ルールベースなので「文脈的に重要」な学びは取れない
- [open] - `OPEN_ISSUES` — 未解決・要調査

## 2026-04-03 21:41 | dotfiles

## 2026-04-03 22:03 | dotfiles

## 2026-04-03 22:07 | dotfiles

## 2026-04-03 22:18 | dotfiles
