# Shopify Hydrogen / App Bridge / Selling Plans / B2B リファレンス
<!-- Hydrogen latest: skeleton@2026.4.2 (released 2026-04-25) -->

> 最終更新: 2026-04-08（公式ドキュメント精査済み）
> ⚠️ B2Bテーマ対応・App Bridge 4の一部API・Remixとの比較は公式URLが404のため未確認

---

## 📋 Recent Changelog

### 2026-04-15: [New CSS variable for mobile safe area insets](https://shopify.dev/changelog/new-css-variable-for-mobile-safe-area-insets)
A new `--shopify-safe-area-inset-bottom` CSS variable is available for embedded apps on Shopify Mobile. Most apps need no code changes, but developers using custom overlay positioning should evaluate this variable.

### 2026-04-01: [Create subscriptions contracts without payment methods](https://shopify.dev/changelog/create-subscriptions-contracts-without-payment-methods)
The `paymentMethodId` field is now optional in `subscriptionContractAtomicCreate` and `subscriptionContractCreate` mutations, enabling migration of subscription contracts that lack valid payment methods.

### 2026-04-01: [Create unpaid orders from subscription billing attempts](https://shopify.dev/changelog/create-unpaid-orders-from-subscription-billing-attempts)
A new `paymentProcessingPolicy` field on `subscriptionBillingAttemptCreate` allows creation of unpaid orders when valid payment methods are unavailable, giving subscribers more flexibility.

---

## 1. Hydrogen（Shopify公式 Headless フレームワーク）

### 概要

ShopifyのHeadlessストアフロントを構築するための**Reactベースのフルスタックフレームワーク**。

```
Hydrogen（アプリ層・Shopify最適化コンポーネント）
  ↓
React Router v7（ルーティング・SSR・データフェッチ）
  ↓
Oxygen（エッジホスティング / Cloudflare Workers上）
```

⚠️ 旧ドキュメントでは「Remixベース」と記載されているが、現在は **React Router v7 が主軸**。`@shopify/remix-oxygen` アダプターは引き続き利用可能だが、デフォルトではない。Viteはビルドツールとして内包されている。

---

### セットアップ

```bash
# プロジェクト作成（Mock.shopのダミーデータで即起動可）
npm create @shopify/hydrogen@latest -- --quickstart

# ローカル開発サーバー起動（localhost:3000）
npx shopify hydrogen dev

# Shopifyストアと紐付け
npx shopify hydrogen link

# 環境変数を本番値に同期
npx shopify hydrogen env pull

# Oxygenへデプロイ
npx shopify hydrogen deploy
```

`.env` の主要変数:
```env
PUBLIC_STOREFRONT_ID=
PUBLIC_STOREFRONT_API_TOKEN=
PRIVATE_STOREFRONT_API_TOKEN=
PUBLIC_CUSTOMER_ACCOUNT_API_CLIENT_ID=
PUBLIC_CUSTOMER_ACCOUNT_API_URL=
```

---

### Storefront API との統合

loaderでサーバーサイドにデータ取得し、クライアントJSを最小化する設計:

```javascript
// app/routes/products.$handle.jsx
export async function loader({params, context}) {
  const {storefront} = context;
  const {product} = await storefront.query(PRODUCT_QUERY, {
    variables: {handle: params.handle},
    cache: storefront.CacheLong(),
  });
  return {product};
}

const PRODUCT_QUERY = `#graphql
  query Product($handle: String!) {
    product(handle: $handle) {
      id
      title
      description
    }
  }
`;
```

---

### キャッシュ戦略（3種）

| 戦略 | Cache-Control値 | 用途 |
|---|---|---|
| `CacheShort()` | `public, max-age=1, stale-while-revalidate=9`（約10秒） | 在庫・価格など頻繁に変わるデータ |
| `CacheLong()` | `public, max-age=3600, stale-while-revalidate=82800`（最大1日） | 商品タイトル・説明など安定データ |
| `CacheNone()` | `no-store` | **顧客固有データ（カート・アカウント）に必須** |

⚠️ 未指定時デフォルト: `public, max-age=1, stale-while-revalidate=86399`

顧客データは2段階で保護が必要:
1. サブリクエスト: `CacheNone()`
2. フルページ: レスポンスヘッダに `private, max-age=<秒>` または `no-store`

---

### Hydrogen vs 通常テーマ の使い分け

| 条件 | 推奨 |
|---|---|
| コード中心の完全カスタムUX / 高度なパーソナライゼーション | **Hydrogen** |
| テーマエディタで非エンジニアが運用 | **通常テーマ（Liquid）** |
| テーマの制約を超えた体験が必要 | **Hydrogen** |
| スピードとコスト優先の標準EC | **通常テーマ** |

---

## 2. App Bridge

### 概要

ShopifyアプリをAdmin内に埋め込むためのUIフレームワーク。アプリはiframe（Web）またはWebView（モバイル）でレンダリングされ、**App BridgeコンポーネントはJavaScriptメッセージのReactラッパー**として動作。実際のUI描画はShopify Admin側が行う。

---

### App Bridge 4（現行）の特徴

- **npmインストール不要**: WebコンポーネントとAPIベース。CDN経由でShopify Adminが自動ロード
- SessionTokenが自動付与される設計（Shopify CLIのアプリテンプレートが自動処理）
- App Bridge 3以前は `@shopify/app-bridge` をnpmインストールして使用

---

### App Bridge 3 SessionToken取得（旧方式 / 参考）

```javascript
import createApp from "@shopify/app-bridge";
import { getSessionToken } from "@shopify/app-bridge/utilities";

const app = createApp({
  apiKey: "YOUR_API_KEY",
  host: new URLSearchParams(location.search).get("host"),
});

// セッショントークン取得（非同期）
const sessionToken = await getSessionToken(app);

// サーバーへのリクエストにBearerとして付与
fetch("/api/endpoint", {
  headers: { Authorization: `Bearer ${sessionToken}` },
});
```

⚠️ App Bridge 4 ではこの手動取得は不要。

---

### 主要 API

| API | 機能 |
|---|---|
| `NavigationMenu` | Admin左サイドバーにナビを表示 |
| `SaveBar` | Admin上部バーの上にセーブ/破棄バーを表示 |
| `TitleBar` | ページタイトルとプライマリ・セカンダリアクション |
| `SessionToken` | 認証トークン取得（v3以前は手動取得、v4は自動） |

❓ Modal・Redirect等の詳細APIは公式URLが404のため未確認。

---

### Polaris との関係

App Bridgeがレイアウト・Admin統合を担い、**Polaris**（`@shopify/polaris`）がUI部品（ボタン、カード、テーブル等）を提供する補完関係。組み合わせることでShopify Admin全体と一貫したUXを実現。

---

## 3. Selling Plans（サブスクリプション）

### オブジェクト階層

```
SellingPlanGroup（販売方法のカテゴリ、例：「定期購入」）
  └── SellingPlan（個別プラン、例：「毎週」「隔週」「毎月」）
        ├── billingPolicy（請求方針：固定 or 繰り返し）
        ├── deliveryPolicy（配送方針）
        ├── pricingPolicies（割引設定）
        └── checkoutCharge（初回支払い額）
```

---

### 必要なスコープ

```
write_products
read_customer_payment_methods
read_own_subscription_contracts
write_own_subscription_contracts
read_shipping
write_shipping
unauthenticated_read_selling_plans   # Storefront API用
```

---

### SellingPlanGroup 作成（Admin GraphQL）

```graphql
mutation CreateSellingPlanGroup($input: SellingPlanGroupInput!, $resources: SellingPlanGroupResourceInput) {
  sellingPlanGroupCreate(input: $input, resources: $resources) {
    sellingPlanGroup {
      id
      name
      sellingPlans(first: 5) { nodes { id name } }
    }
    userErrors { field message }
  }
}
```

変数例（月次 10%オフ）:
```json
{
  "input": {
    "name": "月次定期購入",
    "sellingPlansToCreate": [
      {
        "name": "毎月配送（10%オフ）",
        "billingPolicy": {
          "recurring": { "interval": "MONTH", "intervalCount": 1 }
        },
        "deliveryPolicy": {
          "recurring": { "interval": "MONTH", "intervalCount": 1 }
        },
        "pricingPolicies": [
          {
            "recurring": {
              "adjustmentType": "PERCENTAGE",
              "adjustmentValue": { "percentage": 10.0 }
            }
          }
        ]
      }
    ]
  },
  "resources": {
    "productIds": ["gid://shopify/Product/12345"]
  }
}
```

商品は後から追加も可: `sellingPlanGroupAddProducts` / `sellingPlanGroupAddProductVariants`

---

### Storefront API からのアクセス

```graphql
query ProductWithSellingPlans($handle: String!) {
  product(handle: $handle) {
    id
    title
    sellingPlanGroups(first: 5) {
      nodes {
        name
        appName
        options { name values }
        sellingPlans(first: 10) {
          nodes {
            id
            name
            description
            recurringDeliveries
            priceAdjustments {
              adjustmentValue {
                ... on SellingPlanPercentagePriceAdjustment {
                  adjustmentPercentage
                }
              }
            }
          }
        }
      }
    }
  }
}
```

---

### Webhook イベント

```
selling_plan_groups/create
selling_plan_groups/update
selling_plan_groups/delete
```

`read_own_subscription_contracts` スコープが必要。

---

## 4. B2B / Wholesale（Shopify Plus 限定）

### 概要

**Shopify Plus のみ**利用可能。対応ユースケース: 複数担当者・拠点管理 / 事前交渉済み価格（カタログ）/ 支払い条件（Net 30等）/ 下書き注文・請求書 / 税免除

⚠️ **非対応**: サブスクリプション / プリオーダー / トライアル購入

---

### コアオブジェクト体系

```
Company（企業エンティティ）
  ├── CompanyContact（担当者 / 小売顧客レコードと紐付け）
  │     └── CompanyContactRole（権限・役割）
  └── CompanyLocation（拠点・支店）
        ├── 請求先・配送先住所
        ├── カタログ（価格設定）
        ├── 税免除設定
        └── 支払い条件
```

必要スコープ:
- 読み取り: `read_customers` または `read_companies`
- 書き込み: `write_customers` または `write_companies`

---

### Admin GraphQL API での管理

```graphql
# 企業リスト取得
query {
  companies(first: 10, query: "name:Acme") {
    nodes {
      id
      name
      totalSpent { amount currencyCode }
      ordersCount { count }
      locationsCount { count }
    }
  }
}

# 企業詳細（連絡先・拠点含む）
query {
  company(id: "gid://shopify/Company/1") {
    name
    customerSince
    mainContact { id email firstName lastName }
    contacts(first: 10) { nodes { id email } }
    locations(first: 10) { nodes { id name } }
  }
}

# 企業作成
mutation CreateCompany($input: CompanyCreateInput!) {
  companyCreate(input: $input) {
    company { id name }
    userErrors { field message }
  }
}
```

変数（最小構成）:
```json
{
  "input": {
    "company": { "name": "株式会社サンプル" }
  }
}
```

担当者・拠点は後から `companyContactCreate` / `companyLocationCreate` で追加可能。

その他の主要 mutation: `companyUpdate` / `companyAssignMainContact` / `companyRevokeMainContact`

---

### ライフサイクルフロー

```
マーチャントが Company + CompanyContact 作成
  ↓
Contact が Shopify アカウントでログイン
  ↓
B2B価格カタログが適用された状態でショッピング
  ↓
Shopify が注文を生成
  ↓
アプリが API 連携（請求書発行・ERP連携等）
```

---

### テーマでの B2B 対応

❓ 詳細ドキュメントのURL が404のため未確認。B2B機能はStorefront APIとCustomer Account APIを通じてアクセスするため、**Hydrogenでの実装が推奨**される可能性が高い。

---

## 未確認事項（❓）

| 項目 | 状況 |
|---|---|
| App Bridge 4 の Modal・Redirect API 詳細 | 公式URL 404 |
| B2B テーマ対応の詳細 | 公式URL 404 |
| Vite vs Remix の公式比較 | 公式URL 404 |

> ⚠️ Shopifyのドキュメント構造が2025年以降に大きく再編。旧URLパターンが無効化されており、最新URLは `/docs/storefronts/`、`/docs/api/admin-graphql/latest/`、`/docs/apps/selling-strategies/` 等に移行している。
