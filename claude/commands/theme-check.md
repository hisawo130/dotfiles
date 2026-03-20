Run Shopify theme check validation on the current theme and summarize issues.

Steps:
1. Check if `shopify` CLI is available: `which shopify`
   - If not found, report "shopify CLI not installed" and stop
2. Run: `shopify theme check 2>&1`
3. Parse output and categorize results:
   - **Errors** (blocking): list each with file:line and description
   - **Warnings** (non-blocking): list each with file:line and description
   - **Info**: count only, do not list individually
4. For each **error**, attempt auto-fix:
   - `DeprecatedLazyload` → replace with `loading="lazy"` attribute
   - `{% include %}` usage → replace with `{% render %}`
   - `UnusedAssign` → remove the unused variable assignment
   - Other errors → suggest fix in one line (do not implement)
5. Re-run `shopify theme check` after auto-fixes to confirm resolution
6. Output a verdict: "X errors (Y auto-fixed), Z warnings" or "No issues found"
7. For remaining unfixed errors, list each with:
   - file:line
   - error type
   - recommended fix

Common issues reference:
- `MissingTemplate`: template file referenced but not present → create stub or check file name
- `LiquidSyntaxError`: Liquid tag not properly closed → check `{% if %}{% endif %}` pairs
- `UnusedAssign`: variable assigned but never used → remove assignment
- `DeprecatedLazyload`: replace with native `loading="lazy"`
- `ImgLazyLoading`: use `loading: 'lazy'` in schema image_picker settings
