# Shopify Theme App Extensions & Customer Account UI Extensions リファレンス

> 最終更新: 2026-03-20（公式ドキュメント精査済み）

---

## 1. Theme App Extensions

### 概要と用途

マーチャントがLiquidコードを直接編集せずに、テーマへ動的機能を追加できる仕組み。
テーマエディターのビジュアルUIに自動的に組み込まれる。

**代表的なユースケース:** 商品レビュー表示 / 動的価格 / 3Dモデルビューア / フローティングウィジェット

**テーマ内 App Blockとの違い:**

| 比較軸 | Theme App Extension | テーマ内 App Block |
|---|---|---|
| 管理者 | アプリ開発者がデプロイ | テーマ開発者がコミット |
| 更新方法 | `shopify app deploy` で全店舗即時反映 | テーマのgit pushが必要 |
| テーマ依存 | アプリのCDNに乗る | テーマに同梱 |

✅ Theme App Extension はアプリ側のコードであり、テーマファイルには含まれない。

---

### ファイル構成

```
extensions/
└── my-theme-app-extension/
    ├── assets/          # CSS, JS, 画像（Shopify CDN配信）
    ├── blocks/          # Liquidファイル（App Block / App Embed）
    ├── snippets/        # 再利用Liquidスニペット
    ├── locales/         # 翻訳JSON
    ├── package.json
    └── shopify.extension.toml
```

```toml
# shopify.extension.toml
name = "My Theme App Extension"
handle = "my-theme-app-extension"
type = "theme_app_extension"
```

---

### App Block vs App Embed Block

| 比較軸 | App Block | App Embed Block |
|---|---|---|
| `target` 値 | `"section"` | `"body"` / `"head"` / `"compliance_head"` |
| 配置方法 | テーマエディターのセクション内で追加・移動 | 「App Embeds」タブでトグルON |
| 対応テーマ | **OS 2.0のみ** | OS 2.0 + ヴィンテージテーマ両対応 |
| 用途 | レビュー、評価、コンテンツブロック | フローティングボタン、アナリティクス、SEOタグ |

⚠️ App Block はテーマが `@app` ブロックタイプをサポートするセクションを持つことが前提。

---

### Liquid + Schema の書き方

#### App Block（`target: "section"`）

```liquid
<span style="color: {{ block.settings.color }}">
  {{ block.settings.heading }}
</span>

{% render "review_snippet" %}

{% schema %}
{
  "name": "Product Reviews",
  "target": "section",
  "enabled_on": {
    "templates": ["product"]
  },
  "stylesheet": "reviews.css",
  "javascript": "reviews.js",
  "settings": [
    {
      "label": "見出しテキスト",
      "id": "heading",
      "type": "text",
      "default": "カスタマーレビュー"
    },
    {
      "label": "テキストカラー",
      "id": "color",
      "type": "color",
      "default": "#000000"
    },
    {
      "type": "product",
      "id": "product",
      "label": "商品",
      "autofill": true
    }
  ]
}
{% endschema %}
```

#### App Embed Block（`target: "body"`）

```liquid
<div style="position: fixed; bottom: 20px; right: 20px; z-index: 9999;">
  {{ "chat-widget.js" | asset_url | script_tag }}
</div>

{% schema %}
{
  "name": "Chat Widget",
  "target": "body",
  "javascript": "chat-widget.js",
  "settings": [
    {
      "label": "ウィジェットカラー",
      "id": "widget_color",
      "type": "color",
      "default": "#0066CC"
    }
  ]
}
{% endschema %}
```

#### 条件付き表示（`available_if`）

```liquid
{% schema %}
{
  "name": "Premium Feature Block",
  "target": "section",
  "available_if": "{{ app.metafields.features.premium_enabled }}",
  "settings": []
}
{% endschema %}
```

`available_if` はアプリのメタフィールド（boolean型）で制御する。

---

### `autofill`（動的リソース参照）

```json
{
  "type": "product",
  "id": "product",
  "label": "商品",
  "autofill": true
}
```

`autofill: true` にすると、親セクションが参照しているリソース（商品等）を自動セット。マーチャントの手動設定不要。テキスト・色などには非対応。

---

### マーチャントが有効化する場所

**App Block:** テーマエディター → 対象セクション → 「ブロックを追加」→ アプリ名を選択

**App Embed:** テーマエディター → 左サイドバー「App Embeds」→ アプリ名のトグルをON

**ディープリンク（インストール後に配置画面を自動で開く）:**

```
# 新しい「Apps」セクションに追加
https://<myshopify.com>/admin/themes/current/editor?template=index&addAppBlockId={api_key}/{handle}&target=newAppsSection

# セクショングループ（ヘッダー等）に追加
https://<myshopify.com>/admin/themes/current/editor?template=index&addAppBlockId={api_key}/{handle}&target=sectionGroup:header

# 特定セクションに追加
https://<myshopify.com>/admin/themes/current/editor?template=product&addAppBlockId={api_key}/{handle}&target=sectionId:{sectionID}
```

`api_key` = アプリのClient ID、`handle` = blockのLiquidファイル名（拡張子なし）

---

### 制約・できないこと

| 制約 | 内容 |
|---|---|
| ❌ チェックアウト | App Block / App Embed はCheckoutページ非対応 |
| ❌ ヴィンテージテーマ（App Block） | OS 2.0のJSONテンプレートテーマのみ |
| ⚠️ `enabled_on` / `disabled_on` は排他 | 両方同時に指定不可 |
| ⚠️ `name` は25文字以内 | テーマエディターでの表示名 |
| ⚠️ CSS/JSの重複読み込みなし | 複数ブロックが同一ファイルを参照しても1回だけロード |
| ❌ 外部HTTP通信 | Liquidからの外部fetchは不可 |

---

### デプロイ

```bash
# Extension生成
shopify app generate extension   # タイプで "Theme app extension" を選択

# ローカル開発（ホットリロードあり）
shopify app dev

# デプロイ（全店舗に即時反映 + appバージョン作成）
shopify app deploy
shopify app deploy --version="v1.2.0" --message="レビュー機能追加"
shopify app deploy --no-release   # バージョン作成のみ、公開しない

# 特定バージョンのリリース
shopify app release --version=VERSION

# バージョン一覧
shopify app versions list
```

✅ `shopify app deploy` を実行すると、アプリを使用している全ストアへ自動反映。テーマファイルの変更は不要。

⚠️ アプリのWebサーバー自体のデプロイは別途ホスティング側で行う（CLIのdeployはExtensionのみ）。

---

## 2. Customer Account UI Extensions

### 新 Customer Accounts とは（旧との違い）

| 比較軸 | 旧 Legacy Accounts | 新 Customer Accounts |
|---|---|---|
| UI Extensions対応 | ❌ 非対応 | ✅ 対応 |
| 技術スタック | Liquid | Preact（JSX）+ Web Components |
| カスタマイズ | テーマのLiquidを直接編集 | Extension Targetへコンポーネントを注入 |
| テーマ依存 | テーマに依存 | テーマから独立したサンドボックス |
| B2B対応 | 限定的 | ✅ B2B専用Targetあり（Plus限定） |

✅ Legacy Accountsでは Customer Account UI Extensions は一切使用できない。

---

### Extension Target 一覧

#### Order Index（注文一覧）
```
customer-account.order-index.announcement.render   # ページ上部のアナウンス
customer-account.order-index.block.render          # ブロック追加
```

#### Order Status（注文詳細）
```
customer-account.order-status.announcement.render
customer-account.order-status.block.render
customer-account.order-status.cart-line-item.render-after
customer-account.order-status.cart-line-list.render-after
customer-account.order-status.customer-information.render-after
customer-account.order-status.fulfillment-details.render-after
customer-account.order-status.payment-details.render-after
customer-account.order-status.return-details.render-after
customer-account.order-status.unfulfilled-items.render-after
```

#### Order Action Menu（注文アクション）
```
customer-account.order.action.menu-item.render   # アクションボタン
customer-account.order.action.render             # ボタン押下後のモーダル内
```

#### Profile（プロフィール）
```
customer-account.profile.announcement.render
customer-account.profile.block.render
customer-account.profile.addresses.render-after
```

#### Profile（B2B専用 — Shopify Plusのみ）
```
customer-account.profile.company-details.render-after
customer-account.profile.company-location-addresses.render-after
customer-account.profile.company-location-payment.render-after
customer-account.profile.company-location-staff.render-after
```

#### Full Page（新規ページ作成）
```
customer-account.page.render             # 任意の新規ページ（ウィッシュリスト等）
customer-account.order.page.render       # 特定注文に紐づく新規ページ
```

#### Footer（全ページ共通）
```
customer-account.footer.render-after
```

---

### 開発（Preact + Web Components）

```bash
# Shopify CLI v3.85.3 以上が必要
shopify app generate extension   # → "Customer account UI" を選択
```

```toml
# shopify.extension.toml
api_version = "2026-01"

[[extensions]]
name = "Order Status Extension"
handle = "order-status-ui"
type = "ui_extension"

[[extensions.targeting]]
target = "customer-account.order-status.block.render"
module = "./Extension.jsx"
```

```jsx
// Extension.jsx（Preact）
import { useState } from "preact/hooks";

export default function Extension() {
  const order = shopify.order;  // Preact Signal — 自動再レンダリング

  return (
    <s-stack direction="block">
      <s-banner>注文番号: {order.value?.name} のサポートはこちらへ</s-banner>
      <s-button onClick={() => console.log("clicked")}>サポートに連絡</s-button>
    </s-stack>
  );
}
```

**ナビゲーション:**
```jsx
<s-link href="shopify:customer-account/orders">注文一覧へ</s-link>
<s-link href={`extension:${extension.handle}/detail`}>詳細ページ</s-link>
```

**i18n:**
```jsx
{shopify.i18n.translate("welcomeMessage")}
```

---

### プラン別対応

| 機能 | Basic〜Advanced | Plus |
|---|---|---|
| Order Status / Index / Profile Extensions | ✅ | ✅ |
| Full-page Extensions | ✅ | ✅ |
| B2B向け Profile Targets | ❌ | ✅ |

---

### 制約

| 制約 | 内容 |
|---|---|
| ❌ Legacy Accounts非対応 | 旧アカウントシステムでは動作しない |
| ❌ バンドルサイズ64KB上限 | コンパイル後64KBを超えるとデプロイ不可 |
| ❌ 任意のHTML/scriptタグ不可 | Polaris Web Componentsのみ |
| ❌ CSSオーバーライド不可 | マーチャントのブランド設定を自動継承 |
| ⚠️ 保護データには要申請 | 住所・氏名などのProtected Customer DataはShopifyの審査が必要 |
| ⚠️ サンドボックス隔離 | 各Extensionは独立。他Extensionのデータにアクセス不可 |
| ⚠️ `window` / `document` 制限 | 直接アクセスは制限される |
| ⚠️ ReactではなくPreact | `useState` 等は `preact/hooks` からimport |
| ⚠️ importパス | `@shopify/ui-extensions/customer-account`（`/checkout` は2023-10以降非推奨） |
