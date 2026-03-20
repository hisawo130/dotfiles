
<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://docs.ec-force.com/ecforce_theme_guide/release_note/
- WebFetch: https://docs.ec-force.com/ecforce_theme_guide/about/template
- WebFetch: https://support.ec-force.com/hc/ja/articles/6952681656089
- WebFetch: https://support.ec-force.com/hc/ja/articles/900005807583
- WebFetch: https://docs.ec-force.com/ecforce_theme_guide/about
-->

# ecforce フロントエンド技術リファレンス完全版

> 公式テーマガイド（docs.ec-force.com）を精読して作成。2026/03/18更新分まで対応。

---

## 公式リソース・ドキュメント

- **テーマガイド（公式）**: https://docs.ec-force.com/ecforce_theme_guide — テンプレート仕様書のメインリファレンス
- **テーマガイド：テンプレートの使い方**: https://docs.ec-force.com/ecforce_theme_guide/about/template
- **テーマガイド：はじめに**: https://docs.ec-force.com/ecforce_theme_guide/about
- **Liquid変数 確認先一覧（FAQ）**: https://support.ec-force.com/hc/ja/articles/6952681656089 — ページ別に使える変数のまとめ
- **各テンプレートで使用できる変数（FAQ）**: https://support.ec-force.com/hc/ja/articles/900005807583
- **ec_force_basic_theme（FAQ）**: https://support.ec-force.com/hc/ja/articles/4406944241817 — 標準テーマの仕様
- **テーマ管理 コードの編集（FAQ）**: https://support.ec-force.com/hc/ja/articles/9397313716121
- **テーマ管理 カスタマイズ（FAQ）**: https://support.ec-force.com/hc/ja/articles/900007278443
- **MALL GUIDE テーマガイド（旧）**: https://theme.ec-force.com — コンポーネント一覧
- **リリースノート**: https://docs.ec-force.com/ecforce_theme_guide/release_note/

---

## テンプレートエンジン

**Liquid**（ShopifyのLiquidと同系統）。

> ⚠️ ERB/Slimはecforceテーマには使用しない。Railsバックエンド側はERBだが、テーマ担当者がさわるのはLiquidのみ。

---

## テーマの種類

| テーマ | 名前 | 特徴 |
|-------|------|------|
| ベーシック | `ec_force_basic_theme` | テーマカスタマイズ機能・言語編集・ノーコード編集・自動更新対応。**通常はこちら。** |
| デフォルト | `ec_force_theme_default` | デザインなし（スケルトン）。あらかじめデザインが決まっている場合に使用。サポートへ問い合わせで入手。 |

---

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
{{ include_gon }}                          ← JS変数読み込み（headまたはbody内）
{{ content_for_layout }}                   ← ページコンテンツ挿入
```

### 購入レイアウト固有の必須要素

```liquid
{{- 'shop/amazon_pay' | stylesheet_include_tag -}}   ← AmazonPay CSS
```

隠しフィールド（ログイン時）：
```html
<input type="hidden" id="customer-email">
<input type="hidden" id="customer-number">
```

---

## 共通パーシャル（shared_partial）

| パーシャル | ファイルパス | 必須か |
|-----------|------------|-------|
| header | `ec_force/shop/shared/_header.html.liquid` | 任意（必須記述なし） |
| nav | `ec_force/shop/shared/_nav.html.liquid` | 任意 |
| footer | `ec_force/shop/shared/_footer.html.liquid` | 任意 |
| sidebar | `ec_force/shop/shared/_sidebar.html.liquid` | 任意 |
| cart_modal | `ec_force/shop/shared/_cart_modal.html.liquid` | 任意（機能有効時） |
| **preview_footer** | `ec_force/shop/shared/_preview_footer.html.liquid` | **必須** |
| head_google_tag_manager | `ec_force/shop/shared/_head_google_tag_manager.html.liquid` | GTM使用時 |
| body_google_tag_manager | `ec_force/shop/shared/_body_google_tag_manager.html.liquid` | GTM使用時 |
| available_coupon_list | `ec_force/shop/shared/_available_coupon_list.html.liquid` | クーポン一覧表示時 |

### パーシャルの読み込み方法

```liquid
{% include 'ec_force/shop/shared/header.html' %}
```

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

### cart_modal 必須ID/CLASS

```
id="cart-modal-view"          ← ラッパー
id="cart-modal"               ← モーダル本体
class="close"                 ← 閉じるボタン
id="cart-modal-success"       ← 成功メッセージ
id="cart-modal-failure"       ← エラーメッセージ
id="select-quantity-id-{variant_id}"  ← 数量選択
class="cart-modal-quantity"
class="cart-modal-delete"     ← 削除ボタン
```

### headerで使うLiquid変数

```liquid
{{ yield title }}
{{ yield meta_description }}
{{ yield meta_keywords }}
{{ yield og_image }}
{{ base_info.meta_title }}
{{ base_info.shop_name }}
{{ base_info.meta_description }}
{{ base_info.meta_keyword }}
{{ base_info.sns_ogp_logo.url }}
{{ base_info.copyright }}
```

---

## ページテンプレート一覧

### アセット・全ページ共通

```liquid
{{ file_root_path }}/css/style.css    ← CSS参照ベースURL
{{ file_root_path }}/js/script.js     ← JS参照ベースURL
```

JSタグのパターン（各ページの必須要素）：
```liquid
{{ 'shop/base' | javascript_include_tag }}
{{ 'shop/products' | javascript_include_tag }}
{{ 'shop/carts' | javascript_include_tag }}
{{ 'shop/orders' | javascript_include_tag }}
{{ 'shop/searches' | javascript_include_tag }}
{{ 'shop/contacts' | javascript_include_tag }}
{{ 'shop/info' | javascript_include_tag }}
{{ 'shop/selections' | javascript_include_tag }}
{{ 'shop/customers/sessions' | javascript_include_tag }}
{{ 'shop/customers/registrations' | javascript_include_tag }}
{{ 'shop/customer/base' | javascript_include_tag }}
{{ 'shop/customer/orders' | javascript_include_tag }}
{{ 'shop/customer/subs_orders' | javascript_include_tag }}
```

---

## トップページ

| 項目 | 値 |
|------|---|
| ショップパス | `/shop` |
| PC | `ec_force/shop/base/index.html.liquid` |
| SP | `ec_force/shop/base/index.html+smartphone.liquid` |
| JSタグ | `{{ 'shop/base' \| javascript_include_tag }}` |

主要Liquid変数：`informations`、`hot_product`、`new_products`、`sale_products`、`sale_rankings`、`selections`、`base_info.use_cart`、`pre_order_badge_flg_hash`、`campaign_badge_flg_hash`

---

## 商品一覧

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/products` |
| PC | `ec_force/shop/products/index.html.liquid` |
| SP | `ec_force/shop/products/index.html+smartphone.liquid` |

主要変数：`products`、`products_all`（ページネーション用）、`product.name`、`product.master.sku`、`product.first_price`、`product.thumbnail.url`、`product.average_star`、`product.master.out_of_stock?`、`paginate`

注意：マスターSKUのみカートに追加可能。セット商品対応外。ページネーション件数は管理画面設定と一致させる。

---

## 商品詳細

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/product/{slug}` |
| PC | `ec_force/shop/products/show.html.liquid` |
| SP | `ec_force/shop/products/show.html+smartphone.liquid` |

主要Liquid変数：

```liquid
product.name                           product.master.sku
product.thumbnail.url                  product.master.thumbnails
product.parsed_description             product.parsed_description_mobile
product.parsed_sub_description         product.parsed_sub_description_mobile
product.master.parsed_description      product.master.parsed_description_mobile
product.option01 〜 option10           product.caution / caution02
product.meta_description               product.meta_keywords
product.first_price                    product.first_price_include_tax
product.master.list_price              product.master.list_price_include_tax
product.master.limit_quantity          product.master.min_quantity / max_quantity
product.out_of_stock?                  product.master.out_of_stock?
product.reviews_count                  product.average_star
product.product_categories             product.labels
co_selling_products                    related_products   ← (2025/03からrelated_productsに統一)
pickup_stores                          enabled_pre_order
check_review_reading_rule              check_review_writing_rule
```

**2026/02**: レビュー部分が非同期取得に変更。`js-review-container`クラスを使用。
**2026/03**: `order.target10`変数追加（税率10%対象の小計+手数料・送料込み）。

---

## キーワード検索

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/search?q=...` |
| PC | `ec_force/shop/searches/show.html.liquid` |
| SP | `ec_force/shop/searches/show.html+smartphone.liquid` |

変数：`products`、`products_all`、`recommend_products`（0件時に表示）、`params["q"]`、`paginate`

ソート順：おすすめ・価格・発売日・評価・**人気順**（`product_sale_summaries_total_sale desc`、2023/12追加）

---

## カート

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/cart` |
| PC | `ec_force/shop/carts/show.html.liquid` |
| SP | `ec_force/shop/carts/show.html+smartphone.liquid` |

必須要素：
```
id="cart-show-view"
class="cart_show_login_form"      ← (2025/01追加)
class="cart_show_login_btn"       ← (2025/01追加)
class="line-token-set-btn"
class="auth-infra-token-set-btn"  ← (2024/11追加)
id="AmazonPayLoginBtnMainArea"
id="AmazonLoginButtonMain"
<input type="hidden" name="sign_in_route" value="shop_cart">  ← (2024/10追加 多要素認証対応)
```

主要変数：`order.order_items`、`order.subtotal_with_campaign_discount`、`order.subtotal_tax_with_campaign_discount`、`order.subtotal8/10_tax_with_campaign_discount`、`order.subtotal_include_tax_with_campaign_discount`、`gift_order_items`、`campaign`、`related_products`（2025/03から）、`browsing_histories`、`customer_signed_in`

**2026/01**: Amazon Pay(V2) ログインボタン（`id="AmazonPayLoginBtnMainArea"`）がカートに追加対応。ギフト変数が `gift_oi.aggregated_gift_target_relations_for_cart` に変更。

---

## 注文情報入力（購入フォーム）

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/order/new` |
| PC | `ec_force/shop/orders/new.html.liquid` |
| SP | `ec_force/shop/orders/new.html+smartphone.liquid` |

必須要素：
```
id="new-view"
id="TokenJs"                ← 決済トークン
id="orders-form"            ← 入力フォーム
id="AmazonPayOneClickOrderArea"
id="preview-error"
id="submit"
id="current_order_point_key"
```

部分テンプレート群（★印は別ファイル）：請求先住所・受取方法・複数配送・配送先住所・受取店舗・ラッピング・ポイント・招待コード・クーポン・支払い・配送業者・受取場所（2025/04追加）・配送サイクル・通信欄・カスタム項目・プレビュー・顧客番号・オプトイン・チェックリスト・利用規約

主要変数：`amazon_pay_v2_available`、`customer_signed_in`、`base_info.skip_order_confirm_for_shop?`、`order.error_messages`、`line_settings`、`guest_flag`

---

## 注文確認

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/order/confirm` |
| PC | `ec_force/shop/orders/confirm.html.liquid` |

必須要素：`id="confirm-view"`、`id="ModuleJs"`

主要変数：`order.order_items`、`order.billing_address`、`order.shipping_address`、`order.shipping_carrier.name`、`order.payment.*`、`order.scheduled_to_be_delivered_at`、`order.target10`（2026/03追加）

**2025/02**: 注文完了ボタン上部テキスト表示機能追加。
**2025/01**: `order.single_item_only?` で単品購入判定追加。

---

## サンクスオファー

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/cv_upsell` |
| PC | `ec_force/shop/orders/cv_upsell.liquid` |

必須：`template_for_shop_upsell` のコンテンツ反復、`form_perform.html`、`form_cv_xsell.html`

---

## 注文完了

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/order/complete?order_id=XXX` |
| PC | `ec_force/shop/orders/complete.html.liquid` |

必須変数：`order.number`、`base_info.contact_email`
条件付き：`line_id_linkable`（LINE連携）

---

## ログイン・会員登録（共通画面）

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customers/sign_in` |
| PC | `ec_force/shop/customers/sessions/new.html.liquid` |

フォームフィールド（name属性）：`customer[email]`、`customer[password]`、`customer[remember_me]`
変数：`auth_infra`、`customer`、`shop_form_settings`、`prefectures`、`line_settings`、`encrypted_line_id`

**2024/11**: 認証基盤連携対応（`auth-infra-token-set-btn`クラス追加）。
**2025/01**: `customers_sessions_login_form`、`customers_registration_form` クラス追加。
**2026/01**: Amazon Pay(V2) ログインボタン対応追加。

---

## 会員登録

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customers/sign_up` |
| PC | `ec_force/shop/customers/registrations/new.html.liquid` |

必須フォームフィールド（name属性）：
```
customer[billing_address_attributes][name01/name02]   ← 姓名
customer[billing_address_attributes][kana01/kana02]   ← フリガナ
customer[billing_address_attributes][zip01/zip02]     ← 郵便番号
customer[billing_address_attributes][prefecture_name] ← 都道府県
customer[billing_address_attributes][addr01/addr02]   ← 住所
customer[billing_address_attributes][tel01-03]        ← 電話番号
customer[password]
agree                                                  ← 利用規約同意
```
変数：`customer`、`shop_form_settings`、`prefectures`、`sexes`、`jobs`、`auth_infra`、`customer_password_setting`（2025/05でplaceholder動的化）

---

## 会員情報変更

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customer/edit` |
| PC | `ec_force/shop/customer/base/edit.html.liquid` |

郵便番号フィールドは `type="tel"` + `minSize` バリデーション（2023/06から）。
都道府県フィールドは `prefecture_name` から `prefecture_id`（ID値）に変更（2025/10）。
変数：`current_customer`、`shop_form_settings`、`subs_orders`、`liquid_custom_field`

---

## マイページTOP

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customer` |
| PC | `ec_force/shop/customer/base/show.html.liquid` |

変数：`current_customer.number`、`current_customer.email`、`current_customer.billing_address.*`、`current_customer.point_total`、`current_customer.buy_total`、`orders`（一覧）、`current_customer.granted_coupons`、`liquid_custom_field`

---

## 購入履歴詳細

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customer/orders/{id}` |
| PC | `ec_force/shop/customer/orders/show.html.liquid` |

変数：`order.order_items`、`order.number`、`order.total`、`order.human_state_name`、`order.shipping_address`、`order.payment_method.name`、`receipt_issue_display`（2024/09から。支払い完了時のみ領収書発行可能）

---

## 定期受注一覧

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customer/subs_orders` |
| PC | `ec_force/shop/customer/subs_orders/index.html.liquid` |

変数：`subs_order.number`、`subs_order.subtotal`、`subs_order.human_state_name`、`subs_order.scheduled_to_be_delivered_at`、`subs_order_settings`、`paginate`

---

## 定期受注詳細

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/customer/subs_orders/{id}` |
| PC | `ec_force/shop/customer/subs_orders/show.html.liquid` |

必須要素：`id='subs-order-show-view'`、`id="payment-method-edit-view"`、`id="credit-card"`
変数：`subs_order.human_state_name`、`subs_order.remaining_number_of_orders`、`subs_order.human_payment_schedule_name`、`subs_order.scheduled_to_be_delivered_at`、`liquid_custom_field`

**2025/07**: 利用可能クーポン一覧表示（`available_coupon_list.html.liquid`）対応。
**2024/08**: 定期商品の規格追加機能（バリエーション追加）対応。

---

## フリーページ

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/pages/{slug}` |
| PC | `ec_force/shop/pages/show.html.liquid` |

変数：`page.title`、`parsed_content`、`parsed_content_mobile`、`page.meta_description`、`page.meta_keywords`

---

## セレクション詳細

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/selections/{slug}` |
| PC | `ec_force/shop/selections/show.html.liquid` |

変数：`selection.title`、`selection.parsed_content`、`eye_catch`、`products`、`paginate`、`selection.meta_title`、`selection.meta_description`

---

## お知らせ一覧

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/information` |
| PC | `ec_force/shop/informations/index.html.liquid` |

変数：`informations`（ループ）、`information.slug`、`information.title`、`information.thumbnail.url`、`information.published_at`、`information.information_category.slug/name`、`paginate`

---

## お問い合わせ入力

| 項目 | 値 |
|------|---|
| ショップパス | `/shop/contact/draft` |
| PC | `ec_force/shop/contacts/draft.html.liquid` |

必須フォーム要素：お問い合わせ種別（`contact_types`から）、メール、名前、フリガナ、電話番号、内容、プライバシーポリシー同意
変数：`contact_types`、`current_customer`、`customer_signed_in`、`shop_form_settings`

---

## 全画面共通Liquid変数

```liquid
base_info.shop_name              base_info.contact_email
base_info.copyright              base_info.sns_ogp_logo.url
base_info.use_cart?              base_info.use_cart_modal?
base_info.use_point?             base_info.meta_title
base_info.meta_description       base_info.meta_keyword
customer_signed_in               current_customer
current_order / order            file_root_path
theme_preview_number             full_page_url
```

---

## metaタグ・titleタグの設定方法

各テンプレートファイルの末尾に記述：

```liquid
{% content_for title %}
  {{ product.name }} - {{ base_info.shop_name }}
{% endcontent_for %}

{% content_for meta_description %}
  {{ product.meta_description }}
{% endcontent_for %}

{% content_for meta_keywords %}
  {{ product.meta_keywords }}
{% endcontent_for %}

{% content_for og_image %}
  {{ product.thumbnail.url }}
{% endcontent_for %}
```

---

## テーマカスタマイズCSS

- `theme_customize.css.liquid` — 管理画面「テーマ設定」のカラー・フォント設定を参照するCSS
- 保存すると `theme_customize.css` が自動生成
- カラーピッカーまたは16進数コードで設定

---

## 会員登録必須化（ゲスト購入禁止）

カート画面のゲスト購入リンクを削除するだけで実現：

```html
<!-- このリンクを記述しなければゲスト購入できない -->
<a href="/shop/order/new?register_as_member=0">ゲストとして購入</a>
```

---

## ポイント変数（重要：変更あり）

```liquid
{{ current_customer.available_point_total }}   ← 利用可能ポイント（2024/05以降推奨）
{{ current_customer.pre_redeem_points_amount }} ← 消費予定ポイント（2024/05追加）
{{ current_customer.point_total }}             ← 旧変数（非推奨）
```

---

## LINE連携ボタン実装

```liquid
{% if display_btn == '1' and encrypted_line_id == nil %}
<div class="alert">LINE ID連携の説明</div>
<div class="line_ec">
  <a class="button btn-line line-token-set-btn">LINEでログイン</a>
</div>
{% endif %}
```

必ず各画面の定義済みコンテナ内に配置すること。

---

## 認証基盤連携ボタン（2024/11〜）

```html
<a class="auth-infra-token-set-btn">認証基盤でログイン</a>
```

---

## 多要素認証対応（2024/10〜）

カート・ログイン・サイドバーの各ログインフォームに追加が必要：
```html
<input type="hidden" name="sign_in_route" value="shop_cart">      ← カート
<input type="hidden" name="sign_in_route" value="shop_customers"> ← ログイン画面
```

---

## 開発フロー

1. **テーマを複製**（現在のテーマを直接編集しない）
2. 複製テーマで「コードの編集」
3. **プレビューで確認**（プレビュー以外では非適用テーマは確認不可）
4. 完全に確認後、適用テーマを切り替え

---

## 重要な制約・注意点

| 項目 | 内容 |
|------|------|
| 保存即反映 | 現在のテーマを直接編集して保存するとその瞬間に本番反映。undo不可。 |
| ローカル開発不可 | LiquidはサーバーサイドのみレンダリングされるためLiquid部分のみ確認できない |
| テスト環境 | デフォルトではなし。テーマ複製+プレビューが代替手段 |
| CSSの!important | デフォルトCSSに多用。詳細度競合が起きやすい |
| 新規URLルート | 追加不可 |
| フォーム項目 | 追加・変更不可 |
| サーバーサイド処理 | 変更不可（在庫・決済等） |
| ページネーション | 管理画面の件数設定と`paginate`タグの数値を一致させる必要あり |

---

## 最近の主要変更（2024〜2026）

| 時期 | 変更内容 |
|------|---------|
| 2026/03 | `order.target10`変数追加（税率10%小計+手数料送料込）。レビュー投稿フォームのデータ保持改善。 |
| 2026/02 | 商品詳細のレビューが非同期取得に（`js-review-container`クラス）。ギフト数量上限修正。 |
| 2026/01 | ギフト設定のお届け先ごと個別設定対応。カートのギフト変数名変更（`aggregated_gift_target_relations_for_cart`）。 |
| 2025/10 | 会員情報変更の都道府県フィールドが`prefecture_name`→`prefecture_id`に変更。Amazon Pay(V2)ログインボタンをカート・ログイン・サイドバーに設置可能に。 |
| 2025/09 | お届け先住所変更を`editable_shipping_address`変数で制御（ステータスベース）。 |
| 2025/08 | 店頭受取機能追加（在庫状況表示付き）。 |
| 2025/07 | 利用可能クーポン一覧表示機能（`available_coupon_list.html.liquid`追加）。 |
| 2025/06 | パスワード入力フォームに`customer_password_setting.placeholder`追加。SMS認証時メールアドレス非表示対応。 |
| 2025/05 | パスワード入力プレースホルダーが動的変数化（全5画面）。 |
| 2025/04 | 受取場所（置き配）機能追加（`_view_pickup_location.html.liquid`新規）。 |
| 2025/03 | 関連商品変数が`related_products`に統一（カート・商品詳細）。スマレジ連携対応。 |
| 2025/02 | 注文確認画面に「完了ボタン上部テキスト」表示機能。emailバリデーションクラスが`emailCheckShop`に。 |
| 2025/01 | `order.single_item_only?`追加。O-MOTION不正検知連携対応。各フォームに識別用クラス追加。 |
| 2024/12 | 利用可能クーポン一覧表示（購入フォーム）追加。 |
| 2024/11 | 認証基盤連携対応（`auth-infra-token-set-btn`クラス）。 |
| 2024/10 | 多要素認証対応（`sign_in_route`隠しフィールド）。 |
| 2024/09 | 領収書発行を`receipt_issue_display`で制御（支払完了時のみ）。 |
| 2024/08 | 招待コードURL生成対応。定期商品バリアント追加機能。 |
| 2024/07 | スマレジ会員バーコード画面追加。セット商品フロー改善（カートを経由するよう変更）。 |
| 2024/06 | セレクション一覧画面追加。トップに特集一覧セクション追加。 |
| 2024/05 | 複数お届け先機能追加。キャンペーンバッジ（`campaign_badge_flg_hash`）対応。ポイント変数が `available_point_total` に変更。 |
| 2024/04 | レビューリアクション機能（「参考になった」ボタン、`review.reactions_count`）。 |
| 2024/03 | ギフトサービス機能対応（カート・確認・マイページ）。スマレジ店舗購入対応。 |
| 2024/02 | 定期複数配送サイクル対応（`delivery_cycles/edit.html.liquid`追加）。`concurrent_purchase_group_badge_flg_hash`変数追加。`enabled_pre_order`推奨（`baseinfo.use_pre_order?`は非推奨）。 |
| 2024/01 | 検索0件時おすすめ商品表示（`recommend_products`）。 |
| 2023/12 | 商品一覧・検索・カテゴリ・セレクションに人気順ソート追加。GTM `user_id` を文字列化。 |
| 2023/06 | GTMをhead/body_google_tag_managerパーシャルに分離。郵便番号フィールドを`type="tel"`に統一。店頭受取対応。 |
| 2023/01 | マイページカスタムフィールド表示・編集対応。ポイント交換機能追加。 |
