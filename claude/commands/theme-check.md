Run Shopify theme check validation on the current theme and summarize issues.

Steps:
1. Check if `shopify` CLI is available: `which shopify`
   - If not found, report "shopify CLI not installed" and stop
2. Run: `shopify theme check 2>&1`
3. Parse output and categorize results:
   - **Errors** (blocking): list each with file:line and description
   - **Warnings** (non-blocking): list each with file:line and description
   - **Info**: count only, do not list individually
4. For each error, suggest the fix in one line (do not implement)
5. Output a one-line verdict: "X errors, Y warnings" or "No issues found"

Common issues to explain:
- `MissingTemplate`: template file referenced but not present
- `LiquidSyntaxError`: Liquid tag not properly closed
- `UnusedAssign`: variable assigned but never used
- `DeprecatedLazyload`: replace with native loading="lazy"
- `ImgLazyLoading`: use `loading: 'lazy'` in schema image_picker settings
