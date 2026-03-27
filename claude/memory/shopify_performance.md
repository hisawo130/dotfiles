---
name: shopify_performance
description: ShopifyストアのCore Web Vitals対策・LCP最適化・パフォーマンスベストプラクティス
type: reference
---

<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://performance.shopify.com/blogs/blog
- WebFetch: https://shopify.dev/docs/storefronts/themes/best-practices/performance
-->

## 現状認識（2025〜2026年データ）

- Shopifyストアの **約48%** しかモバイルでCWV全項目をpassしていない
- LCPの中央値: **2.26秒**（許容上限2.5秒と紙一重）
- サードパーティアプリスクリプト **8本以上**: 中央値LCP 3.0秒超え
- サードパーティアプリスクリプト **3本以下**: 中央値LCP 2.0秒未満

## LCP対策（最重要）

### NG: ファーストビュー画像のlazy-load
Shopifyストアの59%が誤って遅延読み込みしている。

### 正しい実装パターン

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

- `fetchpriority="high"` の活用で **0.25〜0.5秒のLCP改善**実績あり

## CLS対策

幅・高さを必ず指定（`image_tag` は自動でheightを設定するため推奨）:

```liquid
{{ image | image_url: width: 800 | image_tag: width: 800, height: 600 }}
```

## アセット管理

- クエリ文字列によるキャッシュバスティングが廃止
- `asset_url` フィルタ経由でのアセット参照を徹底する

## 総合チェックリスト

1. **LCP画像**: `section.index == 1` のセクションで `loading="eager"` + `fetchpriority="high"`
2. **アプリスクリプト削減**: 不使用アプリのスクリプトが残留していないか定期確認
3. **CLS**: 全画像に `width`/`height` 属性（`image_tag` フィルタ使用で自動付与）
4. **`shopify theme check`**: デプロイ前に必ず実行（LCP問題も検出可能）
5. **responsive `sizes`**: `widths:` と `sizes:` を適切に設定してレスポンシブ画像を配信
