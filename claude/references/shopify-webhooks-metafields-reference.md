# Shopify Webhooks & Metafields / Metaobjects リファレンス

<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://shopify.dev/changelog
- WebFetch: https://shopify.dev/docs/api/admin-graphql/latest/objects/Metafield
- WebFetch: https://shopify.dev/docs/apps/build/webhooks
-->

> 最終更新: 2026-03-20（公式ドキュメント精査済み）

---

## 1. Webhooks

### サブスクリプション方式（3種）

| 方式 | URIフォーマット | 備考 |
|------|----------------|------|
| HTTPS | `https://example.com/webhooks` | SSL必須 |
| **Google Pub/Sub** | `pubsub://PROJECT-ID:TOPIC-ID` | ✅ Shopify公式推奨 |
| Amazon EventBridge | `arn:aws:events:REGION::event-source/aws.partner/shopify.com/APP-ID/SOURCE-NAME` | |

Pub/Sub使用時: `delivery@shopify-pubsub-webhooks.iam.gserviceaccount.com` に **Pub/Sub Publisher** ロールを付与する。

---

### 設定方法

#### TOML（全ショップ共通設定 — 推奨）

```toml
[webhooks]
api_version = "2024-07"

[[webhooks.subscriptions]]
topics = ["orders/create", "products/update"]
uri = "pubsub://my-gcp-project:my-gcp-topic"

[[webhooks.subscriptions]]
topics = ["app/uninstalled"]
uri = "/webhooks/app-uninstalled"

# Mandatory webhooks
[[webhooks.subscriptions]]
compliance_topics = ["customers/data_request", "customers/redact", "shop/redact"]
uri = "https://app.example.com/webhooks/compliance"
```

#### GraphQL Admin API（ショップ別の動的設定）

```graphql
mutation {
  webhookSubscriptionCreate(
    topic: ORDERS_CREATE
    webhookSubscription: {
      callbackUrl: "https://example.com/webhooks/orders"
      format: JSON
    }
  ) {
    webhookSubscription { id topic }
    userErrors { field message }
  }
}
```

Pub/Sub の場合:
```graphql
webhookSubscription: {
  pubSubProject: "my-gcp-project"
  pubSubTopic: "my-gcp-topic"
}
```

オプションパラメータ:
- `filter` — イベントフィルタリング（例: `"type:lookbook"`）
- `metafieldNamespaces` — ペイロードに含めるメタフィールド namespace
- `includeFields` — ペイロードに含めるフィールドを絞り込み

⚠️ TOML管理のアプリでは `metafieldNamespaces` パラメータが使えない。

---

### 主要 Webhook トピック一覧

#### Orders
`ORDERS_CREATE` / `ORDERS_UPDATED` / `ORDERS_CANCELLED` / `ORDERS_FULFILLED` / `ORDERS_PARTIALLY_FULFILLED` / `ORDERS_DELETED` / `ORDERS_EDITED` / `ORDERS_PAID` / `ORDER_TRANSACTIONS_CREATE` / `DRAFT_ORDERS_CREATE` / `DRAFT_ORDERS_UPDATE` / `DRAFT_ORDERS_DELETE` / `REFUNDS_CREATE`

#### Products
`PRODUCTS_CREATE` / `PRODUCTS_UPDATE` / `PRODUCTS_DELETE` / `PRODUCT_LISTINGS_ADD` / `PRODUCT_LISTINGS_UPDATE` / `PRODUCT_LISTINGS_REMOVE` / `VARIANTS_IN_STOCK` / `VARIANTS_OUT_OF_STOCK`

#### Customers
`CUSTOMERS_CREATE` / `CUSTOMERS_UPDATE` / `CUSTOMERS_DELETE` / `CUSTOMERS_ENABLE` / `CUSTOMERS_DISABLE` / `CUSTOMERS_MERGE` / `CUSTOMERS_MARKETING_CONSENT_UPDATE` / `CUSTOMER_TAGS_ADDED` / `CUSTOMER_TAGS_REMOVED`

#### Inventory
`INVENTORY_ITEMS_CREATE` / `INVENTORY_ITEMS_UPDATE` / `INVENTORY_ITEMS_DELETE` / `INVENTORY_LEVELS_CONNECT` / `INVENTORY_LEVELS_UPDATE` / `INVENTORY_LEVELS_DISCONNECT`

#### Collections / Themes / App
`COLLECTIONS_CREATE` / `COLLECTIONS_UPDATE` / `COLLECTIONS_DELETE` / `THEMES_CREATE` / `THEMES_UPDATE` / `THEMES_DELETE` / `THEMES_PUBLISH` / `APP_UNINSTALLED` / `APP_SCOPES_UPDATE`

#### Fulfillment / Cart / Checkout
`FULFILLMENTS_CREATE` / `FULFILLMENTS_UPDATE` / `FULFILLMENT_ORDERS_SUBMITTED` 他 / `CARTS_CREATE` / `CARTS_UPDATE` / `CHECKOUTS_CREATE` / `CHECKOUTS_UPDATE` / `CHECKOUTS_DELETE`

#### Subscriptions / Metaobjects
`SUBSCRIPTION_CONTRACTS_CREATE` / `SUBSCRIPTION_CONTRACTS_UPDATE` / `SUBSCRIPTION_BILLING_ATTEMPTS_SUCCESS` / `SUBSCRIPTION_BILLING_ATTEMPTS_FAILURE` / `METAOBJECTS_CREATE` / `METAOBJECTS_UPDATE` / `METAOBJECTS_DELETE`

---

### Mandatory Webhooks（必須3件）

✅ 全 Public App に必須。未実装は App Store 審査落ち。

| トピック | 目的 | 対応期限 |
|----------|------|----------|
| `customers/data_request` | 顧客データ開示リクエスト処理 | 受信後30日以内 |
| `customers/redact` | 顧客データ削除リクエスト処理 | 受信後30日以内 |
| `shop/redact` | アンインストール後のショップデータ削除 | 受信後30日以内 |

- `customers/redact`: 最終注文から6ヶ月経過前はShopifyが送信保留（注文なしの場合は10日遅延）
- `shop/redact`: アンインストール **48時間後** に送信される

---

### HMAC 署名検証

⚠️ HTTPSデリバリー時のみ適用。Pub/Sub / EventBridge はプラットフォーム側が認証を担保。

**必ず raw body（パース前のバイト列）を使うこと。JSONパース後の文字列では検証失敗する。**

```javascript
// Node.js
const crypto = require('crypto');

function verifyWebhook(body, signature, secret) {
  const hash = crypto
    .createHmac('sha256', secret)
    .update(body, 'utf8')
    .digest('base64');
  // タイミング攻撃対策: timingSafeEqual を使う
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(signature));
}

app.post('/webhooks', express.raw({ type: 'application/json' }), (req, res) => {
  const signature = req.headers['x-shopify-hmac-sha256'];
  if (!verifyWebhook(req.body, signature, process.env.SHOPIFY_WEBHOOK_SECRET)) {
    return res.status(401).send('Unauthorized');
  }
  res.status(200).send('OK');
  // 重い処理はQueueに移譲
});
```

```ruby
# Ruby
require 'openssl'
require 'base64'

def verify_webhook(body, signature, secret)
  calculated = Base64.strict_encode64(
    OpenSSL::HMAC.digest('sha256', secret, body)
  )
  Rack::Utils.secure_compare(calculated, signature)
end
```

#### 主要リクエストヘッダー

| ヘッダー | 内容 |
|----------|------|
| `X-Shopify-Topic` | イベント種別（例: `orders/create`） |
| `X-Shopify-Hmac-Sha256` | HMAC署名（Base64） |
| `X-Shopify-Shop-Domain` | ショップドメイン |
| `X-Shopify-Event-Id` | 重複検出用イベントID |
| `X-Shopify-Triggered-At` | イベント発生タイムスタンプ |

---

### デリバリー保証とリトライ

- **At-least-once delivery**（少なくとも1回配信）
- **順序保証: なし**（同一トピックでも順不同）
- **重複: まれに発生**（`X-Shopify-Event-Id` で検出すること）
- **リトライ:** 5秒以内に `2xx` が返らない場合、最大48時間・指数バックオフ

---

### ベストプラクティス

| 項目 | 対応 |
|------|------|
| 冪等処理 | `X-Shopify-Event-Id` をDBに記録し、処理済みなら即200返却してスキップ |
| 非同期処理 | 受信後即200返却し、重い処理はQueue（Sidekiq等）に移譲 |
| 重複対策 | `event_id + shop_domain` にUnique constraint |
| 順序対策 | `updated_at` / `X-Shopify-Triggered-At` で最新性を判断。古いイベントは無視 |
| HMAC検証 | `timingSafeEqual` 必須。raw body使用 |

---

## 2. Metafields

### 基本概念

リソース（Product, Variant等）に紐づく **key-value拡張データ**。識別子: `namespace` + `key` + `ownerType`

#### Namespace の種類

| Namespace | 特徴 |
|-----------|------|
| `$app`（GraphQL）/ `app`（TOML） | アプリ専用。他アプリ・マーチャントは参照不可 |
| `custom`, `specs` 等 | マーチャント所有。全アプリが読み書き可能 |
| `shopify--` | Shopify予約済み |

---

### MetafieldDefinition 作成

```graphql
mutation {
  metafieldDefinitionCreate(
    definition: {
      namespace: "product_details"
      key: "warranty_info"
      name: "保証情報"
      type: "multi_line_text_field"
      ownerType: PRODUCT
      access: {
        admin: MERCHANT_READ_WRITE
        storefront: PUBLIC_READ   # Storefront APIからアクセスする場合
      }
    }
  ) {
    createdDefinition { id namespace key name type { name } }
    userErrors { field message code }
  }
}
```

#### ownerType 主要値
`PRODUCT` / `PRODUCTVARIANT` / `COLLECTION` / `CUSTOMER` / `ORDER` / `DRAFTORDER` / `PAGE` / `BLOG` / `ARTICLE` / `LOCATION` / `MARKET` / `COMPANY` / `SHOP` / `APPINSTALLATION`

#### access.storefront の値
- `PUBLIC_READ` — Storefront API からアクセス可能
- `NONE` — 非公開（デフォルト）

⚠️ Liquidはstorefront設定に関係なく**常にアクセス可能**。

---

### Metafield 取得クエリ（リソース別）

```graphql
# 特定キーで取得
product(id: $id) {
  warranty: metafield(namespace: "product_details", key: "warranty_info") { value }
}

# namespace絞り込み
product(id: $id) {
  specs: metafields(namespace: "specs", first: 10) {
    edges { node { key value type } }
  }
}

# 複数キー指定（Storefront API）
product(id: $id) {
  metafields(identifiers: [
    { namespace: "product_details", key: "warranty_info" }
    { namespace: "specs", key: "material" }
  ]) { namespace key value type }
}
```

対応リソース: `product` / `productVariant` / `collection` / `customer` / `order`

---

### Metafield 作成・更新（`metafieldsSet`）

```graphql
mutation {
  metafieldsSet(metafields: [
    {
      ownerId: "gid://shopify/Product/123456789"
      namespace: "product_details"
      key: "warranty_info"
      value: "3年保証"
      type: "single_line_text_field"
    },
    {
      ownerId: "gid://shopify/Product/123456789"
      namespace: "specs"
      key: "weight"
      value: "{\"value\": 1.5, \"unit\": \"KILOGRAMS\"}"
      type: "weight"
    }
  ]) {
    metafields { id namespace key value type }
    userErrors { field message code }
  }
}
```

⚠️ **`type` は後から変更不可。** 変更する場合は削除→再作成のみ。

### Metafield 削除

```graphql
mutation {
  metafieldsDelete(metafields: [
    { ownerId: "gid://shopify/Product/123456789", namespace: "product_details", key: "warranty_info" }
  ]) {
    deletedMetafields { key namespace ownerId }
    userErrors { field message }
  }
}
```

---

### Liquid からのアクセス

```liquid
{{ product.metafields.product_details.warranty_info.value }}
{{ product.selected_or_first_available_variant.metafields.specs.material.value }}
{{ collection.metafields.seo.description.value }}
{{ customer.metafields.loyalty.points.value }}
{{ shop.metafields.store_info.announcement.value }}

{# JSONメタフィールドのプロパティアクセス #}
{{ product.metafields.information.burn_temperature.value.temperature }}

{# リスト型のイテレーション #}
{% for item in product.metafields.related.products.value %}
  {{ item.product.title }}
{% endfor %}
```

---

### 全データ型一覧

#### 基本型（18種）

| type | 説明 | 値の形式 |
|------|------|----------|
| `single_line_text_field` | 1行テキスト | String |
| `multi_line_text_field` | 複数行テキスト | String |
| `rich_text_field` | リッチテキスト | JSON |
| `number_integer` | 整数 | Integer |
| `number_decimal` | 小数 | String |
| `boolean` | 真偽値 | String ("true"/"false") |
| `color` | 16進数カラーコード | String (#fff123) |
| `date` | 日付（ISO 8601、タイムゾーンなし） | String |
| `date_time` | 日時（ISO 8601、GMT） | String |
| `url` | URL | String |
| `json` | JSON任意データ | JSON |
| `money` | 金額＋通貨コード | JSON |
| `dimension` | 寸法（mm/cm/m/in/ft/yd） | JSON |
| `weight` | 重量（g/kg/oz/lb） | JSON |
| `volume` | 容量（ml/cl/l/m³/fl oz/pt/qt/gal） | JSON |
| `rating` | 評価値（min/maxバリデーション必須） | JSON |
| `link` | テキスト＋URLペア | JSON |
| `id` | 一意なテキストID | String |

計測型のJSON形式:
```json
{ "value": 1.5, "unit": "KILOGRAMS" }    // weight
{ "value": 30.0, "unit": "CENTIMETERS" } // dimension
{ "amount": "19.99", "currency_code": "JPY" } // money
{ "scale_min": "1.0", "scale_max": "5.0", "value": "4.5" } // rating
```

#### 参照型（10種）
`blog_reference` / `collection_reference` / `company_reference` / `customer_reference` / `file_reference` / `metaobject_reference` / `page_reference` / `product_reference` / `product_taxonomy_value_reference` / `variant_reference`

値は `gid://shopify/Product/123` 形式のGlobal ID。

#### リスト型
任意の型に `list.` プレフィックスを付ける（例: `list.single_line_text_field` / `list.product_reference` / `list.color`）。

⚠️ `id` 型への移行は不可。

---

## 3. Metaobjects

### 定義作成（GraphQL）

```graphql
mutation {
  metaobjectDefinitionCreate(definition: {
    type: "size_chart"
    name: "サイズチャート"
    access: { storefront: PUBLIC_READ }
    fieldDefinitions: [
      { key: "product_type", name: "商品カテゴリ", type: "single_line_text_field", required: true }
      { key: "size_data", name: "サイズデータ", type: "json" }
      { key: "image", name: "チャート画像", type: "file_reference" }
    ]
  }) {
    metaobjectDefinition { id type name fieldDefinitions { key type { name } } }
    userErrors { field message }
  }
}
```

### エントリ 作成・更新・取得

```graphql
# 作成
mutation {
  metaobjectCreate(metaobject: {
    type: "size_chart"
    handle: "mens-tops"
    fields: [
      { key: "product_type", value: "メンズトップス" }
    ]
  }) {
    metaobject { id handle fields { key value } }
    userErrors { field message }
  }
}

# handle で取得
query {
  metaobjectByHandle(handle: { type: "size_chart", handle: "mens-tops" }) {
    id handle fields { key value type }
  }
}

# タイプ一覧取得
query {
  metaobjects(type: "size_chart", first: 10) {
    nodes { id handle fields { key value } }
    pageInfo { hasNextPage endCursor }
  }
}

# 削除
mutation {
  metaobjectDelete(id: "gid://shopify/Metaobject/987654321") {
    deletedId
    userErrors { field message }
  }
}
```

### TOML で定義（app-owned）

```toml
[metaobjects.app.author]
name = "著者"
access.admin = "merchant_read_write"
access.storefront = "public_read"

[metaobjects.app.author.fields.full_name]
name = "氏名"
type = "single_line_text_field"

[metaobjects.app.author.fields.bio]
name = "プロフィール"
type = "multi_line_text_field"
```

`shopify app deploy` でデプロイ。GraphQLでのエントリ作成時は type に `$app:author` を使用。

---

## 実務上の注意点まとめ

| 項目 | 注意事項 |
|------|----------|
| Webhook冪等性 | `X-Shopify-Event-Id` をDBに保存し重複スキップ必須 |
| Mandatory webhooks | Public App審査時は3件全部実装必須 |
| HMAC検証 | raw body使用・`timingSafeEqual` 使用・Pub/Subでは不要 |
| Metafield type変更 | 後から変更不可。削除→再作成のみ |
| Storefront公開 | Definition作成時に `access.storefront: PUBLIC_READ` が必要 |
| Liquid vs Storefront API | Liquidはstorefront設定に関係なく常にアクセス可能 |
| app namespace | GraphQLでは `$app`、TOMLでは `app` と表記が異なる |
| Metaobject Storefront | `unauthenticated_read_metaobjects` スコープが必要 |
