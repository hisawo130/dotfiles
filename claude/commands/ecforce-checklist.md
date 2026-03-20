Run the pre-deploy checklist for ecforce theme changes before pushing to production.

Checklist:
1. **テンプレートエンジン確認** — ERB / Slim どちらか明示する
2. **アセットパイプライン確認** — Sprockets / Webpacker どちらか
3. **変更ファイル一覧** — `git diff --name-only HEAD` で出力
4. **注文フロー影響確認** — 以下ページへの副作用をレビュー:
   - カートページ (`cart/`)
   - チェックアウトページ (`checkout/`)
   - サンクスページ (`orders/thank_you`)
5. **ステージング確認** — ステージング環境で表示・動作確認済みか
6. **ロールバック手順** — `git checkout HEAD~1 -- {file}` または管理画面からの復元方法を明記

全項目 OK であれば push を実行。未確認項目があれば停止して報告する。
