---
name: shopify_platform_updates
description: Shopifyプラットフォームの廃止スケジュール・移行先・Winter '26新機能（2026-03現在）
type: reference
---

<!-- UPDATE BEFORE USE
このファイルを参照する前に、以下のソースから最新情報を取得してこのファイルを更新すること。

Sources:
- WebFetch: https://shopify.dev/docs/api/release-notes
- WebFetch: https://www.shopify.com/news/platform-updates
-->

## 廃止スケジュール（要注意）

| 対象 | 期限 | 移行先 | ステータス |
|---|---|---|---|
| checkout.liquid（Plusストア: サンキュー/注文ステータスページ） | 2025年8月28日 | Checkout UI Extensions | ✅ 期限済み（移行完了想定） |
| checkout.liquid（非Plusストア: 同上） | **2026年8月26日** | Checkout UI Extensions | ⚠️ 要対応 |
| Shopify Scripts | **2026年6月30日** | Shopify Functions | ⚠️ 要対応（最優先） |
| JSONメタフィールド値の128KB上限 | **2026年4月** | — | ✅ 期限済み 直近 |
| チェックアウトIDのトークンベース参照化 | **2026年4月** | — | ✅ 期限済み 直近 |

## Checkout Extensibility（checkout.liquid廃止後の代替）

**1. Checkout UI Extensions（推奨）**

| ターゲット | 用途 |
|---|---|
| `purchase.checkout.block.render` | チェックアウト内のカスタムブロック |
| `purchase.thank-you.block.render` | サンキューページのカスタムブロック |
| `purchase.order-status.block.render` | 注文ステータスページ |
| `Validation` | クライアントサイドバリデーション（進行ブロック可能） |

**2. Shopify Functions**（Scriptsの完全な後継）
割引ロジック・配送条件・支払い方法制御をサーバーレスで実装。

**3. Web Pixels**（旧: Additional Scripts / Script Tags）
トラッキング用。`window.Shopify.analytics` 経由はWeb Pixelsに移行。

## API バージョン変更点

- **2025-01**: PrivateMetafield をGraphQL Admin APIから削除 → `app-data metafields` へ移行
- **2026-04（予告）**: JSONメタフィールド値の上限が128KBに制限

## Shopify Winter '26 Edition（2026年1月発表）の注目点

| 機能 | 概要 |
|---|---|
| **Agentic Commerce** | ChatGPT・Copilot・Perplexityなど主要AIチャットで直接販売可能 |
| **Shopify Rollouts** | テーマのA/Bテスト、スケジュールリリースが管理画面から可能 |
| **製品バリエーション上限拡大** | 1商品あたり最大2,048バリエーション（従来100） |
| **Shopify Dev MCP** | Cursor・Claude Codeとの統合。LiquidコードのAI検証・生成 |

## メタフィールド/メタオブジェクト

| | メタフィールド | メタオブジェクト |
|---|---|---|
| 用途 | 特定リソースへの属性付加 | 独立したカスタムコンテンツ |
| 例 | 商品の素材・サイズ感・配送日数 | ブランドストーリー、スタッフ紹介、FAQ |
| Liquidアクセス | `product.metafields.custom.material` | `metaobject.fields.name.value` |

```liquid
{# メタオブジェクト（コレクションページの特集コンテンツ） #}
{% assign brand_story = section.settings.brand_story_metaobject %}
{% if brand_story != blank %}
  <h2>{{ brand_story.fields.title.value }}</h2>
  {{ brand_story.fields.description.value }}
{% endif %}
```

## 優先アクション（2026-03-28 更新）

1. ~~checkout.liquid移行（Plusストア: 2025年8月28日期限）~~ — ✅ 期限済み
2. **Shopify Scripts → Functions 移行計画（2026年6月30日期限）— 最優先**
3. JSONメタフィールド 128KB 上限・チェックアウトID参照化（2026年4月）— 直近要確認
4. checkout.liquid移行（非Plusストア: **2026年8月26日期限**）
5. Theme Blocks / `content_for` の習得 — 新規テーマ開発の前提
6. メタオブジェクトの積極活用（CMSライクなコンテンツ管理、カスタム開発削減）
