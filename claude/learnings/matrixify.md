# Matrixify Learnings
<!-- domain: matrixify — CSV/Excelインポート・エクスポート・Shopifyデータ移行 -->

## 2026-03-31 | 一括フルフィルメント＋出荷通知

- [gotcha] Matrixifyで**未発送注文にフルフィルメントを新規作成**するには `Line: Type = Fulfillment Line` が必須列。この列がないと `Command: UPDATE` が通り `Import Comment: "UPDATE: Found by ID/Name"` と表示されても、フルフィルメントは作成されずステータスも変わらない。

- [pattern] 一括フルフィルメント＋出荷通知の正しい最小カラム構成:
  ```
  Command, ID, Name, Line: Type, Fulfillment: Status, Fulfillment: Tracking Company,
  Fulfillment: Location, Fulfillment: Tracking Number, Fulfillment: Tracking URL, Fulfillment: Send Receipt
  - `Line: Type` = `Fulfillment Line`
  - `Fulfillment: Status` = `success`
  - `Fulfillment: Send Receipt` = `TRUE`（省略または FALSE だと通知送信されない）
  - `Fulfillment: Location` = ロケーション名（発送済み注文をエクスポートして値を確認）

- [pattern] 作業フロー:
  1. 発送済み注文を1件エクスポート → `Fulfillment: Location` の値を確認
  2. 未発送注文を `Fulfillments` データ込みでエクスポート → `ID` と `Name` を取得
  3. 出荷実績CSVと `Name` で突き合わせて追跡番号をマージ
  4. `Line: Type = Fulfillment Line` を追加してインポート

## 2026-03-25 | P130 (顧客データ移行)
- [gotcha] ⚠️ Matrixifyエクスポートの列名は型サフィックス付き: `Metafield: custom.customer_cd [number_integer]`（Shopify純正CSVは `Metafield: custom.customer_cd`）
- [gotcha] 純正CSVとMatrixify CSVを混在させると列名不一致でメタフィールドが空になる
