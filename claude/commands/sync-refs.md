Refresh all reference documents that have an UPDATE BEFORE USE block.

Steps:
1. Scan `~/.claude/references/` for all `.md` files
2. For each file, check if it contains an `UPDATE BEFORE USE` block
3. For files with the block, extract the `Sources:` list:
   - `WebFetch:` sources → fetch each URL
   - `Scan:` sources → read each local path
4. Compare fetched content against the file's current body sections
5. Apply updates where content has changed:
   - New API versions, new features, deprecated items, changed limits
   - Do NOT remove existing content unless it's explicitly superseded
6. If no changes found for a file → mark as "✅ Up to date"
7. After all files processed, commit and push if any were updated (each as a separate Bash call):
   ```
   git -C ~/dotfiles add claude/references/
   git -C ~/dotfiles commit -m "docs: リファレンス一括更新 $(date +%Y-%m-%d)"
   git -C ~/dotfiles push
   ```
8. Output summary table:

| ファイル | ステータス | 変更箇所 |
|---|---|---|
| shopify-reference.md | ✅ Up to date / 🔄 Updated | - |
| shopify-flow-reference.md | ... | ... |
| shopify-custom-app-reference.md | ... | ... |

Note: This command may take 2-3 minutes as it fetches multiple URLs. Run when starting a new Shopify project or monthly.
