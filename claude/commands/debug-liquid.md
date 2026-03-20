Debug Liquid template output by inspecting variables and rendering context.

Usage: /debug-liquid [file] [variable]

Steps:
1. Identify the target template file and variable/object to inspect
2. Add a temporary debug block to the template:

   **For Shopify:**
   ```liquid
   {% comment %}DEBUG START{% endcomment %}
   <pre style="background:#f4f4f4;padding:1rem;font-size:11px;overflow:auto;">
   {{ <variable> | json }}
   </pre>
   {% comment %}DEBUG END{% endcomment %}
   ```

   **For ecforce:**
   ```liquid
   <!-- DEBUG START -->
   <pre style="background:#f4f4f4;padding:1rem;font-size:11px;">
   {{ <variable> | json }}
   </pre>
   <!-- DEBUG END -->
   ```

3. Note the exact line number where the debug block was inserted
4. Remind to:
   - **Shopify:** Push only the target file with `shopify theme push --only <file>`; view in theme preview
   - **ecforce:** Save in the duplicated theme; check the page in browser
5. After debugging is complete, remove the debug block (search for `DEBUG START`/`DEBUG END` markers)
6. Confirm removal and output the clean file path

Common variables to inspect:
- `product` / `product.variants` / `variant`
- `collection` / `collection.products`
- `cart` / `cart.items`
- `customer`
- `settings` (section settings)
- `block.settings`
