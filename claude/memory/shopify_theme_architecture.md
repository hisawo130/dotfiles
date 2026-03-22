---
name: shopify_theme_architecture
description: Dawnバージョン、Theme Blocks/content_for、Sectionスキーマ、Marketのベストプラクティス
type: reference
---

<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://github.com/Shopify/dawn/blob/main/CHANGELOG.md
- WebFetch: https://shopify.dev/docs/storefronts/themes/architecture
-->

## Dawn テーマ

- **現在の安定版: Dawn 15.4.1**（2025年12月5日リリース）
- 15.4.0 でネストされたカートライン（バンドル商品・アドオン）対応
- カスタムテーマは upstream merge が複雑なため `release-notes.md` の差分確認を都度行う

## Theme Blocks（OS 2.0の最重要変更）

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
- `@split` パターン: ネストされたブロックを異なるマークアップコンテキストに分割してレンダリング

## Section Schema ベストプラクティス

```json
{
  "name": "Section Name",
  "tag": "section",
  "class": "section-my-feature",
  "limit": 1,
  "enabled_on": { "templates": ["product", "collection"] },
  "settings": [ ... ],
  "blocks": [ ... ],
  "presets": [ { "name": "Feature Grid" } ]
}
```

**重要ルール:**
- `main-*` 系セクション（main-product.liquid 等）は **presetを持たせない**（他テンプレートへの誤追加防止）
- presetのないセクションはJSONテンプレートから手動追加のみ可能
- `block.shopify_attributes` を必ず各ブロック要素に付与（テーマエディタでの選択・移動を可能にする）
- `enabled_on` / `disabled_on` でテンプレートとgroup（header/footer/aside）を制限する
- `limit` は `1` または `2` のみ指定可能
- `header` type setting で視覚的グルーピングを行う
- セクション独自翻訳は `locales` オブジェクトで定義し、`{{ 'sections.my-section.title' | t }}` でアクセス

**新しい setting type:**
- `article_list` : 複数のブログ記事をまとめて選択できる

## Liquid 新機能

### `section.index` プロパティ
ページ上のセクション表示順を取得。LCP画像の `loading` 属性切り替えに活用:

```liquid
{% assign loading = 'lazy' %}
{% if section.index == 1 %}
  {% assign loading = 'eager' %}
{% endif %}
{{ section.settings.image | image_url: width: 1200 | image_tag: loading: loading, fetchpriority: 'high' }}
```

### 厳格なLiquid構文チェック（2025年〜全テーマ対象）
- 不正なLiquidを含むテーマはエラーになる可能性がある
- `shopify theme check` で事前に検出しておく

## Shopify Markets / 多言語・多通貨

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

## 開発ワークフロー

```bash
shopify theme dev --store=your-store.myshopify.com
shopify theme push --store=your-store.myshopify.com
shopify theme check   # デプロイ前に必ず実行
```

### `shopify.theme.toml` で環境管理:
```toml
[environments.staging]
store = "staging-store.myshopify.com"
theme = "123456789"

[environments.production]
store = "prod-store.myshopify.com"
theme = "987654321"
```

Winter '26で `--environments staging,production` の複数環境同時デプロイが可能に。
