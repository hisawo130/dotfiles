Create a pull request for ecforce theme changes following project conventions.

Steps:
1. Run `git status` and `git log main..HEAD --oneline` to summarize changes
2. Identify affected templates: check if any changed `.html.liquid` files are in purchase flow layouts (`order.html.liquid`, checkout/confirm/complete templates)
3. Calculate purchase flow risk level:
   - 🔴 HIGH: any `order.html.liquid`, confirm, complete template changed
   - 🟡 MED: shared layout or header/footer changed (affects all pages)
   - 🟢 LOW: standalone page template, no shared components changed
4. Check for mobile variants: identify if desktop-changed templates have matching `+smartphone` files
5. Create PR with `gh pr create` using this format:
   - Title: Japanese, concise (under 50 chars)
   - Body template:
     ```
     ## 変更内容
     -

     ## 影響範囲
     - 対象テンプレート（.html.liquid）:
     - モバイル版対応（+smartphoneサフィックス）: 済 / 未 / 不要
     - 購入フローへの影響: [🔴 HIGH / 🟡 MED / 🟢 LOW] — 理由:

     ## 確認方法
     - [ ] 複製テーマでプレビュー確認済み
     - [ ] デスクトップ表示確認済み
     - [ ] モバイル（+smartphone）表示確認済み
     - [ ] 購入フロー全ページ確認（HIGH/MEDの場合必須）: カート→注文入力→確認→完了
     - [ ] アセット（画像/CSS/JS）アップロード済み

     ## デプロイ手順
     1. 複製テーマで最終確認
     2. テーマ切り替えで本番反映

     ## ロールバック
     旧テーマへの切り替えで即時ロールバック可能

     /gemini review
     ```
6. Output the PR URL
