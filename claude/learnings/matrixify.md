# Matrixify Learnings
<!-- domain: matrixify — CSV/Excelインポート・エクスポート・Shopifyデータ移行 -->

## 2026-03-25 | P130 (顧客データ移行)
- [gotcha] ⚠️ Matrixifyエクスポートの列名は型サフィックス付き: `Metafield: custom.customer_cd [number_integer]`（Shopify純正CSVは `Metafield: custom.customer_cd`）
- [gotcha] 純正CSVとMatrixify CSVを混在させると列名不一致でメタフィールドが空になる
