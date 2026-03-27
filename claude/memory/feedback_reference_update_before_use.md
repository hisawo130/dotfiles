---
name: feedback_reference_update_before_use
description: UPDATE BEFORE USEコメントがあるリファレンスファイルは参照前に必ず最新情報を取得して更新する
type: feedback
---

リファレンスファイルに `<!-- UPDATE BEFORE USE -->` コメントがある場合、そのファイルの内容を使う前に、コメント内の `Sources:` URLから最新情報を取得し、ファイルを更新してから使うこと。

**Why:** ecforceは月次でリリースノートが出る更新頻度の高いプラットフォーム。古い情報を参照すると誤った実装をしてしまう。

**How to apply:**
1. `reference_ecforce_platform.md` を読んだとき → まず `https://docs.ec-force.com/ecforce_theme_guide/release_note/` を WebFetch して前回更新日以降の新しいリリースノートを確認する
2. 新しいリリースノートがあれば内容を取得し、ファイルの「最近の主要変更」テーブルと該当ページセクションに追記する
3. ファイル冒頭の更新日（`> 公式テーマガイド（docs.ec-force.com）を精読して作成。YYYY/MM/DD更新分まで対応。`）を更新する
4. その後タスクを実行する

このパターンは `<!-- UPDATE BEFORE USE -->` コメントを持つ他のリファレンスファイルにも同様に適用する。
