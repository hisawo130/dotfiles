Scaffold a new Shopify snippet file following Dawn conventions.

Usage: /snippet-scaffold <snippet-name> [description]

Steps:
1. Determine snippet file path: `snippets/<snippet-name>.liquid`
2. Check if file already exists — abort with warning if so
3. Generate the snippet with:
   - A comment block at the top documenting expected variables (e.g., `{% comment %} Expects: product, variant {% endcomment %}`)
   - Semantic HTML using the snippet name as a BEM root class
   - Conditional rendering guard: `{% if <primary_variable> %}...{% endif %}`
   - No hardcoded strings — all user-facing text via `t:` translation keys or passed variables
4. Write the complete file
5. Output:
   - File path
   - Example `{% render %}` call showing required variables
   - Reminder: snippets cannot access `section.settings` directly — pass values explicitly

Constraints:
- Filename must be kebab-case, no underscores
- Never use `{% include %}` — use `{% render %}` only
- Do not add `{% schema %}` blocks — snippets have no schema
- CSS class on root element must match snippet name for namespace clarity
