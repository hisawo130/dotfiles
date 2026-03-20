Scaffold a new Shopify section file with schema, following Dawn OS2.0 conventions.

Usage: /shopify-section <section-name> [description]

Steps:
1. Determine section file path: `sections/<section-name>.liquid`
2. Check if file already exists — abort with warning if so
3. Generate the section with:
   - Semantic HTML structure (use `<section>` with class matching section name)
   - `{% schema %}` block with:
     - `name`: human-readable Japanese label
     - `tag`: "section"
     - `class`: matches CSS class on root element
     - At minimum: a `heading` setting (type: text) and `color_scheme` setting (type: color_scheme)
     - `presets`: one default preset so section appears in Add Section panel
   - `{% stylesheet %}` block (empty, ready for scoped CSS)
   - `{% javascript %}` block (empty, ready for scoped JS)
4. Write the complete file
5. Output: file path + reminder to add to desired JSON template via theme editor or `templates/*.json`

Constraints:
- Use Dawn naming conventions (color_scheme, section_padding_top, section_padding_bottom)
- Do not use deprecated `{% include %}` — use `{% render %}` for snippets
- All setting IDs in snake_case English, all labels in Japanese
