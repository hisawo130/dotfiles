Detect the current project type and load the appropriate reference document.

Steps:
1. Scan the current directory for project indicators:
   - `shopify.theme.toml` or `config/settings_schema.json` → Shopify theme
   - `ec_force/` or `layouts/ec_force/` → ecforce theme
   - `package.json` with `@shopify/` dependencies → Shopify app
   - `.flow` files → Shopify Flow
   - Otherwise → generic project
2. Report the detected project type
3. Load the matching reference from `~/.claude/references/`:
   - Shopify theme → `shopify-reference.md`
   - Shopify app → `shopify-custom-app-reference.md`
   - Shopify Flow → `shopify-flow-reference.md`
4. If the reference has an `UPDATE BEFORE USE` block, follow the update protocol:
   - Fetch each WebFetch source URL
   - Compare against current content
   - Apply updates if anything changed
   - Commit and push the updated reference
5. Output: detected type + reference file loaded + whether any updates were applied
