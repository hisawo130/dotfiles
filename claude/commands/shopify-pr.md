Create a pull request for the current Shopify theme branch following project conventions.

Steps:
1. Run `git status` and `git log main..HEAD --oneline` to summarize changes
2. Check `config/settings_data.json` is not accidentally included — warn and unstage if staged
3. Detect theme info:
   - Dawn version: `grep -r '"version"' config/settings_schema.json 2>/dev/null | head -1` or package.json
   - Changed sections/snippets: `git diff --name-only main..HEAD | grep -E 'sections/|snippets/'`
4. Auto-check for common issues before creating PR:
   - Any `{% include %}` in changed liquid files? → flag
   - Any `config/settings_data.json` in diff? → unstage and warn
   - Any hardcoded URLs in changed files? → flag
5. Create PR with `gh pr create` using this format:
   - Title: Japanese, concise (under 50 chars)
   - Body template:
     ```
     ## 変更内容
     -

     ## 影響範囲
     - 対象セクション/スニペット:
     - 他セクションへの影響: なし / あり（詳細）
     - テーマバージョン: Dawn X.X.X（自動検出）

     ## 確認方法
     - [ ] デスクトップ表示確認
     - [ ] モバイル表示確認
     - [ ] テーマエディター設定確認（カスタマイザーで開けること）
     - [ ] スキーマ設定の後方互換性確認（設定ID変更なし）

     ## ロールバック
     `git checkout main -- <変更ファイル>` または テーマエディターから旧テーマ切替

     /gemini review
     ```
6. Output the PR URL
