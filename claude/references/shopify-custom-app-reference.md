# Shopify カスタムアプリ リファレンス
<!-- API alert (2026-04-05): stable: 2027-01 → 2026-04 -->

> 最終更新: 2026-03-20（公式ドキュメント精査済み）
> 対象: Storefront API / Checkout Extensibility / Shopify Functions / GraphQL Admin API

---

## 📋 Recent Changelog

### 2026-04-01: [Add Tags to Discounts](https://shopify.dev/changelog/add-tags-to-discounts)
Admin API 2026-04 adds a `tags` field to all discount types, allowing merchants and apps to label, filter, and organize discounts via GraphQL mutations.

### 2026-04-01: [Add Prerequisites to Product Discount Functions](https://shopify.dev/changelog/add-prerequisites-to-product-discount-functions)
Discount Functions now support a `prerequisites` field on product discount candidates, enabling Buy X Get Y (BXGY) logic with `cartLinePrerequisite` specifying ID and required quantity.

### 2026-04-01: [Multi-channel support for sales channel apps](https://shopify.dev/changelog/multi-channel-support-for-sales-channel-apps)
Sales channel apps can now manage multiple channel connections within a single app using new APIs (`channelCreate`, `channelUpdate`, `channelDelete`, etc.); single-channel APIs are now deprecated.

### 2026-04-01: [Removing outdated Polaris reference docs](https://shopify.dev/changelog/removing-outdated-polaris-reference-docs)
Polaris reference documentation now follows GraphQL API versioning policies, with only the last four stable versions documented starting with the 2026-04 release.

### 2026-04-01: [`delegateAccessTokenCreate` mutation now returns `expiresIn`](https://shopify.dev/changelog/delegateaccesstokencreate-mutation-now-returns-expiresin)
The `delegateAccessTokenCreate` mutation now returns an `expiresIn` field indicating token expiration in seconds, available in GraphQL Admin API 2026-04 and later.

### 2026-04-01: [Line item component information now available for draft orders on Customer Account API](https://shopify.dev/changelog/line-item-components-draft-orders-customer-account-api)
Customer Account API 2026-04 adds a `components` field on `DraftOrderLineItem` and a new `flattenComponents` argument to control component representation in response structures.

### 2026-04-01: [Cart and checkout validation adds billing address and PO number error targets](https://shopify.dev/changelog/cart-and-checkout-validation-adds-billing-address-and-po-number-error-targets)
As of API 2026-04, Cart and Checkout Validation Functions can now validate billing addresses and purchase order numbers with new checkout field error targets.

### 2026-04-01: [Payment method identifier now required for customerPaymentMethodRemoteCreate](https://shopify.dev/changelog/payment-method-identifier-now-required-for-customerpaymentmethodremotecreate)
Starting with API 2026-07, payment method identifier fields become required for `customerPaymentMethodRemoteCreate` with Stripe, Authorize.net, or Braintree inputs. Update integrations before the 2026-07 release.

### 2026-04-01: [Report Fulfillment Order progress with new fulfillmentOrderReportProgress GraphQL mutation](https://shopify.dev/changelog/report-fulfillment-order-progress-with-new-fulfillmentorderreportprogress-graphql-mutation)
The new `fulfillmentOrderReportProgress` mutation enables 3PLs and fulfillment apps to report work-in-progress on orders with optional status notes, supported in Admin API 2026-04.

### 2026-03-31: [New rejection reason codes in Payments Apps API](https://shopify.dev/changelog/new-rejection-reason-codes-in-payments-apps-graphql-api)
The Payments Apps API now provides more granular decline reason codes for rejected payment sessions. New codes added to `PaymentSessionStateRejectedReason` enum alongside a new source field for better error handling.

### 2026-03-30: [Role-based access control and org management for partners](https://shopify.dev/changelog/role-based-access-control-and-org-management-for-partners)
Partner organizations now support role-based access control with seven system roles covering org administration, store access, and app development. Dev stores, client transfer stores, and collaborator stores are unified in one dashboard; existing permissions are automatically migrated with no action required.

### 2026-03-25: [The Shopify CLI app release --force flag is deprecated and will be removed](https://shopify.dev/changelog/the-shopify-cli-app-release-force-flag-is-deprecated-and-will-be-removed)
The `--force` flag on `shopify app deploy` and `shopify app release` commands will be removed in May 2026. Replace with `--allow-updates` and `--allow-deletes` flags for more granular CI/CD control.

---

## 1. Storefront API

### エンドポイント

```
POST https://{store}.myshopify.com/api/{version}/graphql.json
Content-Type: application/json
X-Shopify-Storefront-Access-Token: {token}
```

バージョンは年4回（`2025-01`, `2025-04`, `2025-07`, `2025-10`, `2026-01` 等）。URLへの明示的な指定を推奨。

---

### 認証方式

| 方式 | ヘッダー | 複雑度上限 | 用途 |
|------|----------|------------|------|
| **トークンなし** | 不要 | 1,000 | 公開情報のみ（商品・コレクション・カート等） |
| **Publicトークン** | `X-Shopify-Storefront-Access-Token` | 高い（❓具体値非公開） | ブラウザ・モバイルアプリ（クライアントサイド） |
| **Privateトークン** | `X-Shopify-Storefront-Access-Token` | 高い（❓具体値非公開） | サーバー・Hydrogenバックエンド（サーバーサイド） |

**トークン取得（GUI）:** 管理画面 → Headlessチャネルインストール → 「Create storefront」

**トークン取得（Admin API）:**
```javascript
const response = await adminApiClient.post({
  path: 'storefront_access_tokens',
  data: { storefront_access_token: { title: 'My Storefront Token' } }
});
```

⚠️ 1ショップあたりアクティブなストアフロント（トークン）は最大100個まで。

---

### トークンなし vs トークン必須

| 機能 | トークンなし | トークン必須 |
|------|:-----------:|:-----------:|
| Products / Collections | ✓ | — |
| Cart（読み書き） | ✓ | — |
| Pages / Blogs / Articles | ✓ | — |
| Selling Plans / Search | ✓ | — |
| Customer情報 | ✗ | ✓ |
| Product Tags | ✗ | ✓ |
| Metaobjects / Metafields | ✗ | ✓ |
| Menu | ✗ | ✓ |

---

### 主要クエリ・ミューテーション

#### Products 取得

```graphql
query {
  products(first: 3, query: "product_type:snowboards", sortKey: TITLE) {
    edges {
      cursor
      node {
        id
        title
        handle
        vendor
        variants(first: 5) {
          edges {
            node {
              id
              price { amount currencyCode }
              availableForSale
            }
          }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

**`products` 主要引数:**
- `first` / `last` / `after` / `before`: カーソルベースページネーション
- `query`: `available_for_sale`, `product_type`, `tag`, `title`, `vendor`, `variants.price` 等
- `sortKey`: ID, TITLE, PRICE, BEST_SELLING, CREATED_AT, UPDATED_AT

#### Cart 操作

```graphql
# カート作成
mutation {
  cartCreate(
    input: {
      lines: [{ quantity: 1, merchandiseId: "gid://shopify/ProductVariant/XXX" }]
      buyerIdentity: { email: "customer@example.com", countryCode: JP }
    }
  ) {
    cart {
      id
      lines(first: 10) { edges { node { id quantity } } }
      cost { totalAmount { amount currencyCode } }
    }
  }
}

# カートライン更新
mutation {
  cartLinesUpdate(
    cartId: "gid://shopify/Cart/abc123"
    lines: { id: "gid://shopify/CartLine/1", quantity: 3 }
  ) {
    cart { id }
  }
}

# カートにメタフィールドをセット（API v2023-04〜）
mutation {
  cartMetafieldsSet(
    metafields: [{
      ownerId: "gid://shopify/Cart/abc123"
      key: "public.gift_message"
      type: "single_line_text_field"
      value: "Happy Birthday!"
    }]
  ) {
    metafields { namespace key value type }
  }
}
```

---

### Rate Limit

- リクエスト数による制限なし。**クエリ複雑度（cost points）** による制限
- トークンなし: 上限 **1,000**
- トークンあり: より高い（❓具体値は公式非公開）
- セキュリティ問題検知時: HTTP `430` エラー
- ⚠️ `Shopify-Storefront-Buyer-IP` ヘッダーに購入者IPを渡すことを推奨（bot対策）

---

### Headless 構成早見表

```
[クライアントサイド]
ブラウザ → Storefront API（Public Token）→ Shopify

[サーバーサイド]
バックエンド → Storefront API（Private Token）→ Shopify
           → Admin API（Admin Token）→ Shopify
```

---

## 2. Checkout Extensibility

### Extension の種別

| Extension | 説明 |
|-----------|------|
| **UI Extensions** | チェックアウトUI要素の追加・カスタマイズ |
| **Functions** | ビジネスロジック（割引・配送・バリデーション） |
| **Web Pixel Extensions** | トラッキング・分析 |
| **Payments Extensions** | 支払いオプション制御 |

⚠️ **checkout.liquid はShopify Plus専用。2025年8月28日廃止。** Extensionへの移行必須。

---

### UI Extensions — Extension ターゲット一覧（全34個）

#### 汎用ブロック（最も使用頻度が高い）
```
purchase.checkout.block.render
purchase.thank-you.block.render
```

#### アドレス
```
purchase.address-autocomplete.format-suggestion
purchase.address-autocomplete.suggest
```

#### お知らせバナー
```
purchase.thank-you.announcement.render
```

#### フッター / ヘッダー
```
purchase.checkout.footer.render-after
purchase.thank-you.footer.render-after
purchase.checkout.header.render-after
purchase.thank-you.header.render-after
```

#### コンタクト / 顧客情報
```
purchase.checkout.contact.render-after
purchase.thank-you.customer-information.render-after
```

#### 注文サマリー
```
purchase.checkout.cart-line-item.render-after
purchase.checkout.cart-line-list.render-after
purchase.checkout.reductions.render-after
purchase.checkout.reductions.render-before
purchase.thank-you.cart-line-item.render-after
purchase.thank-you.cart-line-list.render-after
```

#### 配送
```
purchase.checkout.delivery-address.render-after
purchase.checkout.delivery-address.render-before
purchase.checkout.shipping-option-item.details.render
purchase.checkout.shipping-option-item.render-after
purchase.checkout.shipping-option-list.render-after
purchase.checkout.shipping-option-list.render-before
```

#### 支払い
```
purchase.checkout.payment-method-list.render-after
purchase.checkout.payment-method-list.render-before
```

#### 店舗受取 / ピックアップポイント
```
purchase.checkout.pickup-location-list.render-after
purchase.checkout.pickup-location-list.render-before
purchase.checkout.pickup-location-option-item.render-after
purchase.checkout.pickup-point-list.render-after
purchase.checkout.pickup-point-list.render-before
```

#### ナビゲーション
```
purchase.checkout.actions.render-before
```

---

### UI Extensions — 開発環境

```bash
# 新規アプリ作成
shopify app init --name my-checkout-app

# Extension生成
shopify app generate extension
# → "Checkout UI Extension" を選択

# 開発サーバー起動
shopify app dev
```

**利用可能なコンポーネント:** Polaris Web Components（`s-banner`, `s-text`, `s-button`, `s-stack`, `s-heading`, `s-image` 等）

---

### UI Extensions — 制約・できないこと

| 制約 | 内容 |
|------|------|
| バンドルサイズ | **64KB以内**（コンパイル済みJS） |
| DOM操作 | **不可**（チェックアウトDOMへの直接アクセス禁止） |
| 任意HTML | **不可**（Polaris Web Componentsのみ） |
| CSSカスタマイズ | **不可**（マーチャントのブランド設定を自動継承） |
| Shopify Plusのみ | Information / Shipping / Payment ステップの static target |

---

### Validation（サーバーサイドバリデーション）

**Function API:** `cart.validations.generate.run`

**対応サーフェス:** B2B / Cart / Checkout / Draft Order / Shopify Admin / Storefront / Accelerated Checkout

**非対応:** Create Order API / Order Edit / POS / Pre-order / Subscriptions

**ユースケース:** トークンゲーティング・年齢確認・B2B数量制限・フラッシュセール数量制限 等

**Input クエリ例:**
```graphql
query Input {
  cart {
    lines {
      quantity
      merchandise {
        ... on ProductVariant {
          id
          product { tags }
        }
      }
    }
    buyerIdentity {
      email
      isAuthenticated
    }
  }
  buyerJourney {
    step  # CART_INTERACTION | CHECKOUT_INTERACTION | CHECKOUT_COMPLETION
  }
}
```

⚠️ **1ストアあたり有効化できるValidation Functionは最大25個。**

---

## 3. Shopify Functions

### 対応 Function API 一覧

| Function API | 用途 |
|-------------|------|
| **Discount** | カートライン・配送への割引作成 |
| **Cart Transform** | カートラインの変換・表示変更 |
| **Cart and Checkout Validation** | チェックアウト中のサーバーサイドバリデーション |
| **Delivery Customization** | 配送方法のリネーム・並び替え・非表示 |
| **Payment Customization** | 支払い方法の非表示・並び替え |
| **Fulfillment Constraints** | フルフィルメントグループのパラメータ設定 |
| **Order Routing Location Rule** | 在庫引当ロケーションの優先度制御 |
| **Pickup Point Delivery Option Generator** | ピックアップポイント生成（⚠️ Unstable） |
| **Local Pickup Delivery Option Generator** | 店舗受取オプション生成（⚠️ Unstable） |

---

### 開発言語

| 言語 | 推奨度 | 備考 |
|------|--------|------|
| **Rust** | ★ 強く推奨 | 大量カートでも高パフォーマンス |
| **JavaScript** | 可 | パフォーマンスは劣る。小規模ロジック向け |

両言語とも **WebAssembly (Wasm)** にコンパイルして実行。

---

### アーキテクチャ

```
Input（GraphQLクエリで定義）
  ↓
Function本体（Wasm）
  ↓
Output（Shopifyが実行するオペレーションのJSON）
```

⚠️ FunctionはURLでの直接呼び出し不可。Shopifyが購入フロー中に自動実行。

---

### デプロイ

```bash
shopify app dev     # ローカル開発・プレビュー
shopify app deploy  # 本番デプロイ（アプリと一緒にリリース）
```

**`shopify.extension.toml` 例（Discount Function）:**
```toml
name = "my-discount-function"
type = "discounts"
api_version = "2025-10"

[build]
command = "cargo build --release --target wasm32-wasip1"
path = "target/wasm32-wasip1/release/discount.wasm"
```

---

### 制限事項

| 項目 | 内容 |
|------|------|
| プラン制限 | **カスタムアプリでFunctionsを使う場合はShopify Plus必須** |
| 実行モデル | URLでの直接呼び出し不可 |
| fetch アクセス | Enterprise限定（❓詳細非公開） |
| タイムアウト / メモリ上限 | ❓公式非公開 |
| パブリックアプリ | 全プランで利用可能（App Store経由） |
| Validation数上限 | 1ストア最大25個 |

---

## 4. GraphQL Admin API

### エンドポイント

```
POST https://{store}.myshopify.com/admin/api/{version}/graphql.json
Content-Type: application/json
X-Shopify-Access-Token: {admin_access_token}
```

---

### 認証方式

| 方式 | 対象 |
|------|------|
| **OAuth (Authorization Code Grant)** | 非埋め込みアプリ |
| **Token Exchange** | 埋め込みアプリ |
| **カスタムアプリトークン** | 管理画面で直接発行 |

---

### Rate Limit（コストベース）

レスポンスに含まれる情報:
```json
{
  "extensions": {
    "cost": {
      "requestedQueryCost": 10,
      "throttleStatus": {
        "maximumAvailable": 1000,
        "currentlyAvailable": 990,
        "restoreRate": 50
      }
    }
  }
}
```

---

### 商品クエリ例（Admin API）

```graphql
query {
  products(first: 10, query: "status:active", sortKey: TITLE) {
    nodes {
      id
      title
      handle
      vendor
      productType
      status
      variants(first: 5) {
        nodes {
          id
          price
          inventoryQuantity
          sku
        }
      }
      media(first: 3) {
        nodes {
          ... on MediaImage {
            image { url altText }
          }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

**フィルター例:**
```
product_type:snowboards
status:active
updated_at:>2024-01-01
vendor:MyBrand
inventory_total:>0
published_status:published
```

---

## 5. GraphiQL の使い方（3種類）

### 方法1: Shopify CLI から起動（推奨）

```bash
cd my-app
shopify app dev
# 起動後に g キーを押す → ブラウザでGraphiQLが開く
```

アプリと同じアクセス権限を完全継承。最もフル機能で使える。

### 方法2: GraphiQLアプリをインストール

URL: `https://shopify-graphiql-app.shopifycloud.com/`

開発ストアにインストールして使用。
⚠️ 他のアプリが所有するデータにはアクセス不可（スコープ制限あり）。

### 方法3: デモストア（読み取り専用）

開発ストアなしでクエリ実行可能。Explorer タブと Docs タブでスキーマを視覚的に探索。

---

## 未確認事項（❓）

| 項目 | 状況 |
|------|------|
| Storefront API トークンあり複雑度上限の具体値 | 公式非公開 |
| Shopify Functions タイムアウト・メモリ上限 | 公式非公開 |
| Customer API の詳細クエリ例 | 対象URLが404 |
| Discount Function 入出力スキーマ詳細 | 対象URLが404 |
| Checkout Validation の Rust/JS コード例 | 対象URLが404 |

→ `shopify.dev/docs/api/functions` のリファレンスまたはGraphiQLのスキーマ探索から確認を推奨。
