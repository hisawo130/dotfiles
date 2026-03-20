Push the current Shopify theme to the store and verify the result.

Steps:
1. Run `git status` to confirm there are no untracked sensitive files (settings_data.json changes, etc.)
2. Check `config/settings_data.json` diff — confirm any changes are intentional
3. Run `shopify theme push` (or `shopify theme push --only` if scope is limited)
4. Output the affected theme URL for visual confirmation
5. List files changed in this push

After push, remind the user to:
- Check desktop and mobile preview in the theme editor
- Verify sections that share the same CSS namespace are unaffected
