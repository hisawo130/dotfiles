# Shopify リファレンス

> 最終更新: 2026-03-20（公式ドキュメント精査済み）
> 対象バージョン: Dawn 15.4.1 / Online Store 2.0 / Winter '26 Edition

---

## 1. Dawn テーマ

- **現在の安定版: Dawn 15.4.1**（2025年12月5日リリース）
- 15.4.0 でネストされたカートライン（バンドル商品・アドオン）対応
- カスタムテーマは upstream merge が複雑なため `release-notes.md` の差分確認を都度行う

---

## 2. Theme Blocks（OS 2.0の最重要変更）

`/blocks` フォルダに独立したLiquidファイルとして定義。複数セクション間で再利用可能。

```liquid
{{- 'section-name.css' | asset_url | stylesheet_tag -}}
{% content_for 'blocks' %}
```

```liquid
{# 静的ブロック単体呼び出し #}
{% content_for 'block', type: "button", id: "unique-id", color: "red" %}
```

- `variant: "dark"` のようにカスタム属性を渡せる（ブロック内で `{{ variant }}` 参照）
- 公式が認める特殊ブロック型は `@theme` と `@app` の2種のみ

---

## 3. Section Schema ベストプラクティス

```json
{
  "name": "Section Name",
  "tag": "section",
  "class": "section-my-feature",
  "limit": 1,
  "enabled_on": { "templates": ["product", "collection"] },
  "settings": [
    { "type": "header", "content": "Layout" },
    {
      "type": "select",
      "id": "layout",
      "label": "Layout",
      "options": [
        { "value": "grid", "label": "Grid" },
        { "value": "list", "label": "List" }
      ],
      "default": "grid"
    }
  ],
  "blocks": [
    {
      "type": "card",
      "name": "Card",
      "limit": 6,
      "settings": [
        { "type": "image_picker", "id": "image", "label": "Image" },
        { "type": "richtext", "id": "description", "label": "Description" }
      ]
    }
  ],
  "presets": [
    {
      "name": "Feature Grid",
      "blocks": [{ "type": "card" }, { "type": "card" }, { "type": "card" }]
    }
  ]
}
```

**重要ルール:**
- `main-*` 系セクション（main-product.liquid 等）は **presetを持たせない**のが慣習（公式明記なし・コミュニティベストプラクティス）
- presetのないセクションはJSONテンプレートから手動追加のみ可能
- `block.shopify_attributes` を必ず各ブロック要素に付与（テーマエディタでの選択・移動を可能にする）
- `enabled_on` / `disabled_on` でテンプレートとgroup（header/footer/aside）を制限する
- `limit` は `1` または `2` のみ指定可能
- `header` type setting で視覚的グルーピングを行う
- セクション独自翻訳は `locales` オブジェクトで定義し `{{ 'sections.my-section.title' | t }}` でアクセス
- **新 setting type**: `article_list`（複数のブログ記事をまとめて選択可能、2026年1月追加）
- テーマアプリ拡張のアプリブロック上限: **25 → 30** に拡大

---

## 4. Liquid 新機能

### `section.index` プロパティ

ページ上のセクション表示順を取得。LCP画像の `loading` 属性切り替えに活用:

```liquid
{% assign loading = 'lazy' %}
{% if section.index == 1 %}
  {% assign loading = 'eager' %}
{% endif %}
{{ section.settings.image | image_url: width: 1200 | image_tag: loading: loading, fetchpriority: 'high' }}
```

### `unit_price_with_measurement` フィルタ（Dawn 15.4.0〜）

単位あたり価格をフォーマット付きで表示:
```liquid
{{ variant | unit_price_with_measurement }}
```

### 厳格なLiquid構文チェック（2026年1月13日〜全テーマ対象）
- 不正なLiquidを含むテーマはエラーになる可能性がある
- テーマとテーマアプリ拡張の両方が対象
- `shopify theme check` で事前に検出しておく

---

## 5. パフォーマンス最適化（Core Web Vitals）

**現状（2025〜2026年データ）:**
- Shopifyストアの **約48%** しかモバイルでCWV全項目をpassしていない
- LCPの中央値: **2.26秒**（許容上限2.5秒と紙一重）
- サードパーティアプリスクリプト 8本以上 → 中央値LCP 3.0秒超え
- サードパーティアプリスクリプト 3本以下 → 中央値LCP 2.0秒未満

### LCP対策（最重要）

Shopifyストアの **59%がファーストビュー画像を誤ってlazy-load** している。

```liquid
{# section.index を使ってファーストビューの画像を特定 #}
{% assign img_loading = 'lazy' %}
{% assign img_priority = 'auto' %}
{% if section.index == 1 %}
  {% assign img_loading = 'eager' %}
  {% assign img_priority = 'high' %}
{% endif %}

{{ section.settings.hero_image
  | image_url: width: 1500
  | image_tag:
    loading: img_loading,
    fetchpriority: img_priority,
    widths: '375, 750, 1100, 1500',
    sizes: '100vw' }}
```

`fetchpriority="high"` で **0.25〜0.5秒のLCP改善**実績あり。

### CLS対策

```liquid
{{ image | image_url: width: 800 | image_tag: width: 800, height: 600 }}
```

`image_tag` は自動でheightを設定するため推奨。

### アセット管理
- クエリ文字列によるキャッシュバスティングが廃止 → `asset_url` フィルタ経由のアセット参照を徹底

### チェックリスト
1. `section.index == 1` のセクションで `loading="eager"` + `fetchpriority="high"`
2. 不使用アプリのスクリプト残留を定期確認
3. 全画像に `width`/`height` 属性
4. デプロイ前に `shopify theme check` 実行
5. `widths:` と `sizes:` を適切に設定

---

## 6. Shopify Markets / 多言語・多通貨

**URLはハードコードしない:**
```liquid
{# NG #}
<a href="/cart">Cart</a>
{# OK #}
<a href="{{ routes.cart_url }}">Cart</a>
```

JavaScript では `window.Shopify.routes.root` を使用。

**SEO: 構造化データ内の通貨:**
```liquid
"priceCurrency": "{{ cart.currency.iso_code }}"
```

**制限事項:**
- 多通貨はShopify Payments必須
- マーケット数は最大50
- 非Plusプランは価格リスト機能なし（パーセント調整のみ）

---

## 7. 廃止スケジュール（要注意）

| 対象 | 期限 | 移行先 |
|---|---|---|
| checkout.liquid（**Shopify Plus専用**）サンキュー/注文ステータスページ | **2025年8月28日** | Checkout UI Extensions |
| Shopify ScriptsとCheckout Extensionsの共存終了 | **2026年6月30日** | Shopify Functions |
| JSONメタフィールド値の128KB上限適用 | **2026年4月（API 2026-04〜）** | 値を分割 or file型に移行 |
| チェックアウトIDのWebhookペイロードからの除去 | **2026年4月（API 2026-04〜）** | checkout tokenを使用 |
| レガシー顧客アカウント | **新規ストアでは利用不可** | 新・顧客アカウントUI |
| `inventorySetScheduledChanges` mutation | **廃止済み** | — |

---

## 8. Checkout Extensibility

**Checkout UI Extensions（推奨）:**

| ターゲット | 用途 |
|---|---|
| `purchase.checkout.block.render` | チェックアウト内のカスタムブロック |
| `purchase.thank-you.block.render` | サンキューページのカスタムブロック |
| `purchase.order-status.block.render` | 注文ステータスページ |
| `Validation` | クライアントサイドバリデーション（進行ブロック可能） |

**Shopify Functions**（Scriptsの後継）: 割引ロジック・配送条件・支払い方法制御をサーバーレスで実装。2026年6月30日以降はScriptsとの共存不可。

**Web Pixels**（旧: Additional Scripts / Script Tags）: トラッキング用。

---

## 9. メタフィールド / メタオブジェクト

| | メタフィールド | メタオブジェクト |
|---|---|---|
| 用途 | 特定リソースへの属性付加 | 独立したカスタムコンテンツ |
| 例 | 商品の素材・サイズ感・配送日数 | ブランドストーリー、スタッフ紹介、FAQ |
| Liquidアクセス | `product.metafields.custom.material` | `metaobject.fields.name.value` |

```liquid
{% assign brand_story = section.settings.brand_story_metaobject %}
{% if brand_story != blank %}
  <h2>{{ brand_story.fields.title.value }}</h2>
  {{ brand_story.fields.description.value }}
{% endif %}
```

**2025-01 API変更**: PrivateMetafield を GraphQL Admin API から削除 → `app-data metafields` へ移行。

**2026 API変更**:
- `metaobjectDefinitionCreate` の `fieldDefinitions` 入力がオプションに
- MetaobjectDefinition に `createdAt`/`updatedAt` フィールド追加
- JSON型メタフィールド値は **128KB上限** が2026-04 APIから適用

---

## 10. 開発ワークフロー

```bash
shopify theme dev --store=your-store.myshopify.com   # ローカル開発
shopify theme push --store=your-store.myshopify.com  # テーマをストアにpush
shopify theme pull --store=your-store.myshopify.com  # テーマをストアからpull
shopify theme check                                   # デプロイ前に必ず実行
shopify theme push --environments staging,production  # 複数環境同時デプロイ（Winter '26〜）
```

**`shopify.theme.toml` で環境管理:**
```toml
[environments.staging]
store = "staging-store.myshopify.com"
theme = "123456789"

[environments.production]
store = "prod-store.myshopify.com"
theme = "987654321"
```

---

## 11. Winter '26 新機能（2026年1月）

| 機能 | 概要 |
|---|---|
| **Agentic Commerce** | ChatGPT・Copilot・Perplexityで直接販売可能 |
| **Shopify Rollouts** | テーマA/Bテスト・スケジュールリリースが管理画面から可能 |
| **バリエーション上限拡大** | 1商品あたり最大2,048バリエーション（従来100） |
| **Shopify Dev MCP** | Cursor・Claude Codeと統合。Liquidコードの検証・生成 |

---

## 12. 関連リファレンス

| ドキュメント | パス | 内容 |
|---|---|---|
| **Shopify Flow リファレンス** | `~/.claude/references/shopify-flow-reference.md` | トリガー・アクション・条件の完全一覧、HTTP Request詳細、ベストプラクティス |

---

## 優先アクション

1. **checkout.liquid移行（Plusストアのみ: 2025年8月28日期限）** — サンキュー・注文ステータスページが対象
2. **Theme Blocks / `content_for` の習得** — 新規テーマ開発の前提
3. **LCP画像の `loading="eager"` 確認** — `section.index == 1` を全テーマに適用
4. **Shopify Scripts → Functions 移行計画** — 2026年6月30日に共存終了
5. **メタオブジェクトの積極活用** — CMSライクなコンテンツ管理でカスタム開発削減
