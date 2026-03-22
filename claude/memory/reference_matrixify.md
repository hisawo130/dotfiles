---
name: Matrixify 完全リファレンス
description: Shopify Matrixify（旧Excelify）の機能・仕様・コマンド・Metafields・Images・料金・落とし穴（公式ドキュメント直接取得済み）
type: reference
---

<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://matrixify.app/documentation/
-->

# Matrixify 完全リファレンス

公式ドキュメント（https://matrixify.app/documentation/）を直接取得して作成。

---

## 対応データ型（18シート）

Products, Smart Collections, Custom Collections, Customers, Companies,
Discounts, Draft Orders, Orders, Payouts, Pages, Blog Posts, Redirects,
Activity, Files, Metaobjects, Menus, Metafields, Shop

---

## ファイル仕様

| 形式 | 仕様 |
|------|------|
| Excel (.xlsx) | シート名がデータ型を決定（例：`Products`, `Customers`） |
| CSV | ZIP 圧縮、ファイル名で自動認識 |
| Google Sheets | 直接インポート・エクスポート対応 |
| エンコーディング | UTF-8（BOM なし推奨） |
| 最大サイズ | 20GB / ジョブ |

**自動 CSV 変換トリガー：**
- 行数 500,000 超
- 列数 10,000 超
- セル内文字数 32,767 超

---

## Command（グローバル）

`Command` 列で動作を制御。列がない場合はシートごとのデフォルトが適用。

| コマンド | 動作 | 失敗条件 |
|----------|------|----------|
| `NEW` | 新規作成のみ。既存（ID/Handle一致）があれば失敗 | 既存item存在時 |
| `MERGE` | 既存あれば更新、なければ新規作成（upsert） | なし |
| `UPDATE` | 既存のみ更新。見つからなければ失敗 | item不在時 |
| `REPLACE` | ⚠️ 完全削除後ファイルデータのみで再作成。ファイル非含有データはすべて消える | - |
| `DELETE` | 削除。見つからなければ失敗 | item不在時 |
| `IGNORE` | スキップ | - |

**シート別デフォルト：**
- Products / Smart Collections / Customers 等 → `MERGE`
- Custom Collections → `UPDATE`（⚠️ 前回調査の誤り：MERGEではない）
- Orders / Draft Orders → `NEW`

---

## サブ Command（各エンティティ内）

| 対象 | 列名 | 有効値 | デフォルト |
|------|------|--------|-----------|
| タグ | `Tags Command` | MERGE / DELETE / REPLACE | MERGE |
| 画像 | `Image Command` | MERGE / DELETE / REPLACE | MERGE |
| バリアント | `Variant Command` | MERGE / UPDATE / DELETE / REPLACE | MERGE |
| 住所 | `Address Command` | MERGE / DELETE / REPLACE | MERGE |
| ロケーション | `Location: Command` | NEW / MERGE / UPDATE / REPLACE / DELETE | MERGE |
| コレクション内製品 | `Product: Command` | MERGE / DELETE / REPLACE | MERGE |
| ブログコメント | `Comment Command` | MERGE / UPDATE / DELETE | MERGE |

---

## Products シート

### アイテム識別の優先順位

ID → Handle → Title（ID が最速。存在しない ID は3段階フォールバックで約3倍遅い）

Handle は必ず含めること。

### 主要列

| 列名 | 特記事項 |
|------|---------|
| `ID` | Shopify 自動生成。新規作成時は空白 |
| `Handle` | URL スラッグ。自動的に小文字変換・特殊文字除去・非ラテン文字転写。255字上限 |
| `Title` | 新規作成時のみ必須 |
| `Status` | Active / Archived / Draft / Unlisted |
| `Gift Card` | **作成時のみ設定可。更新後の変更不可** |
| `Tags` | カンマ区切り |
| `Template Suffix` | 代替テーマテンプレート指定 |

### バリアント識別の優先順位

Variant ID → Variant SKU → Variant Barcode

SKU が重複している場合は全バリアントが対象になるため Variant ID を使うのが安全。

---

## Metafields

### 列ヘッダー形式

```
Metafield: namespace.key [type]
Variant Metafield: namespace.key [type]    （バリアント用）
```

namespace 省略時のデフォルトは `global`。

namespace や key 内にドットを含む場合は `\.` でエスケープ：
```
Metafield: my\.namespace.my\.key [type]
```

### 型推論の順序（type 未指定時）

1. Shopify 内の既存 metafield の型を使用
2. ストアのメタフィールド定義から namespace/key で検索
3. セルの値から推論

### サポート型一覧

| カテゴリ | 型 | list 対応 |
|---------|---|----------|
| テキスト | `single_line_text_field` / `multi_line_text_field` / `rich_text_field` | ✅ |
| 数値 | `number_integer` / `number_decimal` | ✅ |
| 真偽値 | `boolean` | ✅ |
| 日時 | `date` (YYYY-MM-DD) / `date_time` (ISO 8601) | ✅ |
| 計量 | `weight` / `volume` / `dimension`（単位指定必須） | ✅ |
| 参照 | `product_reference` / `collection_reference` / `variant_reference` / `file_reference` | ✅ |
| その他 | `color` / `url` / `json` / `rating` | ✅ |

list 型は `list.single_line_text_field` のように `list.` プレフィックスを付ける。

### 削除方法

セルを空白にして MERGE インポートするだけで削除される。

---

## Images

### 複数画像の2つの記述方法

**方法1：セミコロン区切り（1セルに複数URL）**
```
Image Src: https://example.com/img1.jpg ; https://example.com/img2.jpg
```
セミコロン + スペースで区切る（スペースなしでも動作する場合あり）。

**方法2：複数列**
```
Image Src | Image Alt Text | Image Position | Image Src (2) | Image Alt Text (2) | Image Position (2)
```
各画像に個別の Alt Text / Position を割り当てる場合に使う。

両方法の混在も可。

### 制限

- 最大 250 枚 / 製品
- 公開直リンク必須（Google Drive・Dropbox 共有リンクも対応）

### Image Command

| 値 | 動作 |
|----|------|
| `MERGE` | 既存画像を保持して新規追加 |
| `REPLACE` | 既存画像を全削除して新規画像のみ保持 |
| `DELETE` | 指定画像を削除 |

---

## Collections

### Custom Collections

- デフォルト Command：**UPDATE**
- `Product: Command`（MERGE / DELETE / REPLACE）でコレクション内の製品関連付けを制御
- `Product: Position` で手動ソート順を指定（数値、1始まり）
- Handle 更新時は自動的にリダイレクト生成

### Smart Collections

- デフォルト Command：MERGE（推定）
- `Must Match`：all conditions / any condition
- `Rule: Product Column` / `Rule: Relation` / `Rule: Condition` でルールを定義

---

## Files シート

| 列名 | I/O | 特記事項 |
|------|-----|---------|
| `ID` | Export | GID形式 |
| `File Name` | I/O | 拡張子を元ファイルと一致させること |
| `Command` | Import | NEW / MERGE / UPDATE / REPLACE / DELETE / IGNORE |
| `Link` | I/O | Shopify CDN URL |
| `Alt Text` | I/O | 画像の SEO 説明文 |
| `Type` | I/O | IMAGE / FILE / VIDEO / MODEL_3D |
| `Status` | Export | Failed / Uploaded / Processing / Ready |
| `MIME Type` | Export | RFC 2045 準拠 |
| `Size MB` | Export/Filter | フィルタとして使用可 |

---

## 料金プラン（公式サイト取得）

| プラン | 月額 | Products | Customers | Orders | Redirects |
|--------|------|----------|-----------|--------|-----------|
| Demo | 無料 | 10 | 10 | 10 | 10 |
| Basic | $20/30日 | 5,000 | 2,000 | 1,000 | 10,000 |
| Big | $50/30日 | 50,000 | 20,000 | 10,000 | 100,000 |
| Enterprise | $200/30日 | 無制限 | 無制限 | 無制限 | 無制限 |

⚠️ **前回調査の誤り修正：** Basic プランは Customers 2,000 / Orders 1,000（5,000ではない）

制限は**1ジョブごと**。月次・日次・時間単位の制限なし。何度でも実行可能。

**プラン別追加機能：**
- Big 以上：バッチインポート、5並列スレッド
- Enterprise：10+並列スレッド、2同時手動ジョブ

**全プラン共通：** Metafields / Scheduling / FTP・SFTP 統合 / ストア1個追加無料

---

## 重要な落とし穴・注意事項

1. **REPLACE は全列必須** — 含めなかった列のデータが消える（例：Image 列を省略 → 全画像削除）
2. **存在しない ID はパフォーマンス劣化** — 常に Handle も併記すること
3. **SKU 重複は危険** — 同 SKU の全バリアントが対象になる。Variant ID を使うこと
4. **Custom Collections のデフォルトは UPDATE** — MERGE ではないため、新規作成時は Command: MERGE を明示
5. **Gift Card は作成後変更不可** — 作成時のみ設定できる
6. **インポート前バックアップは必須** — 大規模変更は取り返し不可
7. **結果ファイル（Result CSV）** — インポート失敗時にダウンロード可。各行のエラー詳細を確認
8. **Metafield の型変更** — 既存 metafield の型変更は Shopify Admin で先に行うかキー変更が必要

---

## 公式ドキュメント

- https://matrixify.app/documentation/
- https://matrixify.app/documentation/products/
- https://matrixify.app/documentation/metafields/
- https://matrixify.app/documentation/list-of-commands-across-matrixify-sheets/
- https://matrixify.app/documentation/files/
- https://matrixify.app/documentation/smart-collections/
- https://matrixify.app/documentation/custom-collections/
- https://matrixify.app/tutorials/import-several-product-images-from-one-row/
- https://matrixify.app/pricing/
