Push the current Shopify theme to the store and verify the result.

Steps:
1. Run `git status` to confirm working tree state
2. Check `config/settings_data.json` diff — warn if it contains unintentional changes; ask before including
3. Identify changed files: `git diff --name-only HEAD` or `git diff --name-only main..HEAD`
4. Push only changed files using: `shopify theme push --only <file1> --only <file2> ...`
   - Exception: if all changes should go up, run `shopify theme push` without `--only`
5. Output the preview URL from the push output
6. List the files pushed

After push, remind to:
- Check desktop and mobile in the Shopify theme editor preview
- Verify sections sharing the same CSS namespace are unaffected
- Check that theme editor settings still load correctly (no broken schema keys)
