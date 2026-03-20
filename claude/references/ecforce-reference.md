# ecforce リファレンス

<!-- UPDATE BEFORE USE
Sources:
  - WebFetch: https://docs.ec-force.com/ecforce_theme_guide/release_note/
  - WebFetch: https://docs.ec-force.com/ecforce_theme_guide/about/template
  - WebFetch: https://support.ec-force.com/hc/ja/articles/6952681656089
-->

> 最終更新: 2026-03-20（公式ドキュメント精査済み）
> 対象: ecforce テーマ（Liquid テンプレート / ベーシックテーマ）

---

## 公式ドキュメント・URL集

- **テーマガイド（公式）**: https://docs.ec-force.com/ecforce_theme_guide
- **テンプレートの使い方**: https://docs.ec-force.com/ecforce_theme_guide/about/template
- **Liquid変数 一覧（FAQ）**: https://support.ec-force.com/hc/ja/articles/6952681656089
- **各テンプレート変数（FAQ）**: https://support.ec-force.com/hc/ja/articles/900005807583
- **ベーシックテーマ仕様（FAQ）**: https://support.ec-force.com/hc/ja/articles/4406944241817
- **コードの編集（FAQ）**: https://support.ec-force.com/hc/ja/articles/9397313716121
- **テーマカスタマイズ（FAQ）**: https://support.ec-force.com/hc/ja/articles/900007278443
- **リリースノート**: https://docs.ec-force.com/ecforce_theme_guide/release_note/

---

## テンプレートエンジン

**Liquid**（ShopifyのLiquidと同系統）。ERB/Slimはテーマには使用しない。

## テーマの種類

| テーマ | 名前 | 特徴 |
|-------|------|------|
| ベーシック | `ec_force_basic_theme` | テーマカスタマイズ・言語編集・ノーコード編集・自動更新対応。**通常はこちら。** |
| デフォルト | `ec_force_theme_default` | デザインなし（スケルトン）。サポートへ問い合わせで入手。 |

## ファイル命名規則

- 拡張子：`.html.liquid`
- スマホ版：`+smartphone` サフィックス（例: `show.html+smartphone.liquid`）
- パーシャル：アンダースコアプレフィックス（例: `_header.html.liquid`）

---

## レイアウト（3種類）

| レイアウト | ファイルパス | 対象ページ |
|-----------|------------|---------|
| 通常 | `layouts/ec_force/shop.html.liquid` | カート・購入フロー以外の全ページ |
| 購入 | `layouts/ec_force/shop/order.html.liquid` | カート・注文入力・確認・完了 |
| パスワード保護 | `layouts/ec_force/password.html.liquid` | パスワード保護画面 |

### レイアウト共通の必須要素

```liquid
{{ 'header_prepend' | shop_shared_tag }}  ← <head> 直後
{{ 'header_append' | shop_shared_tag }}   ← </head> 直前
{{ 'body_prepend' | shop_shared_tag }}    ← <body> 直後
{{ 'body_append' | shop_shared_tag }}     ← </body> 直前
{{ include_gon }}                          ← JS変数読み込み
{{ content_for_layout }}                   ← ページコンテンツ挿入
```

### 購入レイアウト固有

```liquid
{{- 'shop/amazon_pay' | stylesheet_include_tag -}}   ← AmazonPay CSS
```

---

## 共通パーシャル

| パーシャル | 必須 |
|-----------|------|
| header, nav, footer, sidebar | 任意 |
| **preview_footer** | **必須** |
| cart_modal | 任意（機能有効時） |
| head/body_google_tag_manager | GTM使用時 |
| available_coupon_list | クーポン一覧表示時 |

読み込み: `{% include 'ec_force/shop/shared/header.html' %}`

### preview_footer 必須実装

```html
<div id="preview-footer-view" data-preview="{{ theme_preview_number }}">
  <a class="js-close-preview" rel="nofollow"
     data-method="put"
     href="/shop/close_preview?current_path={{ full_page_url }}">
    プレビューを終了
  </a>
</div>
```

---

## アセット参照

```liquid
{{ file_root_path }}/css/style.css
{{ file_root_path }}/js/script.js
```

JSタグ:
```liquid
{{ 'shop/base' | javascript_include_tag }}
{{ 'shop/products' | javascript_include_tag }}
{{ 'shop/carts' | javascript_include_tag }}
{{ 'shop/orders' | javascript_include_tag }}
```

---

## ページテンプレート一覧

### トップ
| パス | PC | SP |
|------|----|----|
| `/shop` | `ec_force/shop/base/index.html.liquid` | `+smartphone` |

変数: `informations`, `hot_product`, `new_products`, `sale_products`, `sale_rankings`, `selections`

### 商品一覧
| パス | PC | SP |
|------|----|----|
| `/shop/products` | `ec_force/shop/products/index.html.liquid` | `+smartphone` |

変数: `products`, `products_all`, `paginate`

### 商品詳細
| パス | PC | SP |
|------|----|----|
| `/shop/product/{slug}` | `ec_force/shop/products/show.html.liquid` | `+smartphone` |

主要変数: `product.name`, `product.master.sku`, `product.thumbnail.url`, `product.parsed_description`, `product.first_price`, `product.first_price_include_tax`, `product.reviews_count`, `product.average_star`, `co_selling_products`, `related_products`

### 検索
| パス | PC |
|------|----|
| `/shop/search?q=...` | `ec_force/shop/searches/show.html.liquid` |

変数: `products`, `recommend_products`（0件時）, `params["q"]`, `paginate`

### カート
| パス | PC |
|------|----|
| `/shop/cart` | `ec_force/shop/carts/show.html.liquid` |

必須ID: `cart-show-view`
変数: `order.order_items`, `order.subtotal_with_campaign_discount`, `gift_order_items`, `related_products`, `browsing_histories`

### 注文入力
| パス | PC |
|------|----|
| `/shop/order/new` | `ec_force/shop/orders/new.html.liquid` |

必須ID: `new-view`, `TokenJs`, `orders-form`, `submit`

### 注文確認
| パス | PC |
|------|----|
| `/shop/order/confirm` | `ec_force/shop/orders/confirm.html.liquid` |

必須ID: `confirm-view`, `ModuleJs`
変数: `order.order_items`, `order.billing_address`, `order.shipping_address`, `order.target10`（2026/03追加）

### 注文完了
| パス | PC |
|------|----|
| `/shop/order/complete` | `ec_force/shop/orders/complete.html.liquid` |

変数: `order.number`, `base_info.contact_email`, `line_id_linkable`

### ログイン
| パス | PC |
|------|----|
| `/shop/customers/sign_in` | `ec_force/shop/customers/sessions/new.html.liquid` |

### 会員登録
| パス | PC |
|------|----|
| `/shop/customers/sign_up` | `ec_force/shop/customers/registrations/new.html.liquid` |

### マイページ
| パス | PC |
|------|----|
| `/shop/customer` | `ec_force/shop/customer/base/show.html.liquid` |

### 購入履歴詳細
| パス | PC |
|------|----|
| `/shop/customer/orders/{id}` | `ec_force/shop/customer/orders/show.html.liquid` |

### 定期受注
| パス | PC |
|------|----|
| `/shop/customer/subs_orders` | `ec_force/shop/customer/subs_orders/index.html.liquid` |

---

## 全画面共通Liquid変数

```liquid
base_info.shop_name              base_info.contact_email
base_info.copyright              base_info.use_cart?
base_info.use_point?             base_info.meta_title
customer_signed_in               current_customer
file_root_path                   theme_preview_number
full_page_url
```

---

## metaタグ設定方法

```liquid
{% content_for title %}{{ product.name }} - {{ base_info.shop_name }}{% endcontent_for %}
{% content_for meta_description %}{{ product.meta_description }}{% endcontent_for %}
{% content_for meta_keywords %}{{ product.meta_keywords }}{% endcontent_for %}
{% content_for og_image %}{{ product.thumbnail.url }}{% endcontent_for %}
```

---

## 重要な制約

| 項目 | 内容 |
|------|------|
| 保存即反映 | 現在のテーマ直接編集 → 保存した瞬間に本番反映。undo不可。 |
| ローカル開発不可 | Liquid はサーバーサイドのみ |
| CSS `!important` | デフォルトCSS多用。詳細度競合に注意。 |
| 新規URLルート | 追加不可 |
| フォーム項目 | 追加・変更不可 |
| サーバーサイド処理 | 変更不可 |

---

## 開発フロー

1. テーマを**複製**（直接編集しない）
2. 複製テーマで「コードの編集」
3. **プレビューで確認**
4. 完全に確認後、適用テーマを切り替え

---

## 最近の主要変更（2024〜2026）

| 時期 | 変更内容 |
|------|---------|
| 2026/03 | `order.target10`変数追加。レビュー投稿フォームのデータ保持改善。 |
| 2026/02 | 商品詳細レビューが非同期取得に（`js-review-container`）。 |
| 2026/01 | ギフト設定の個別設定対応。カートのギフト変数名変更。Amazon Pay(V2)カート対応。 |
| 2025/10 | 都道府県が`prefecture_name`→`prefecture_id`に変更。 |
| 2025/08 | 店頭受取機能追加。 |
| 2025/07 | 利用可能クーポン一覧表示。 |
| 2025/04 | 受取場所（置き配）機能追加。 |
| 2025/03 | 関連商品変数が`related_products`に統一。 |
| 2025/01 | `order.single_item_only?`追加。多要素認証対応。 |
| 2024/11 | 認証基盤連携対応。 |
| 2024/10 | 多要素認証対応（`sign_in_route`隠しフィールド）。 |
| 2024/05 | ポイント変数が`available_point_total`に変更。複数お届け先対応。 |
