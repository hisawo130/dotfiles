Create a pull request for the current Shopify theme branch following project conventions.

Steps:
1. Run `git status` and `git log main..HEAD --oneline` to summarize changes
2. Check `config/settings_data.json` is not accidentally included (warn if it is)
3. Create PR with `gh pr create` using this format:
   - Title: Japanese, concise (under 50 chars)
   - Body template:
     ```
     ## 変更内容
     -

     ## 影響範囲
     - 対象ページ/セクション:
     - 他セクションへの影響: なし / あり（詳細）

     ## 確認方法
     - [ ] デスクトップ表示確認
     - [ ] モバイル表示確認
     - [ ] テーマエディター設定確認

     /gemini review
     ```
4. Output the PR URL
