# Shopify Flow リファレンス

<!-- UPDATE BEFORE USE
Sources:
  - WebFetch: https://help.shopify.com/en/manual/shopify-flow/reference/triggers
  - WebFetch: https://help.shopify.com/en/manual/shopify-flow/reference/actions
  - WebFetch: https://help.shopify.com/en/manual/shopify-flow/reference/variables
  - WebFetch: https://help.shopify.com/en/manual/shopify-flow/reference/actions/send-http-request
  - WebFetch: https://shopify.dev/changelog
-->

> 最終更新: 2026-03-20（公式ドキュメント・Changelog精査済み）
> 対象: Shopify Flow（全プラン Basic 以上で利用可能）

---

## 1. 概要

Shopify Flow はノーコードの自動化ツール。**Trigger → Condition → Action** の3要素でワークフローを構築する。

| 要素 | 役割 | 例 |
|---|---|---|
| **Trigger** | ワークフローを起動するイベント | 注文作成、在庫変動、顧客作成 |
| **Condition** | 分岐条件（if/else） | 注文金額 > ¥10,000、タグに "VIP" を含む |
| **Action** | 実行されるタスク | タグ追加、Slack通知、HTTP リクエスト送信 |

**利用可能プラン:**

| プラン | Flow利用 | 備考 |
|---|---|---|
| Starter ($5) | ✗ | |
| Basic ($29〜) | ✓ | |
| Grow ($79〜) | ✓ | |
| Advanced ($299〜) | ✓ | Send HTTP request 利用可 |
| Plus ($2,300〜) | ✓ | カスタムアプリタスク利用可 |

---

## 2. トリガー一覧（100+）

### 注文（Order）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Order created | 注文が作成された時 | 新規注文通知、タグ付け |
| Order paid | 支払い完了時 | 後続処理開始、CRM連携 |
| Order fulfilled | フルフィルメント完了時 | 配送完了通知 |
| Order cancelled | 注文キャンセル時 | 在庫復元チェック |
| Order risk analyzed | リスク分析完了時 | 高リスク注文の自動ホールド |
| Order transaction created | 決済トランザクション作成時 | 決済監視 |
| Refund created | 返金発生時 | 返金アラート |

### 顧客（Customer）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Customer created | 新規顧客登録時 | ウェルカム施策 |
| Customer joined segment | セグメントに参加時 | VIP昇格処理 |
| Customer left segment | セグメントから離脱時 | ステータス変更 |
| Customer tags added | タグ追加時 | 連鎖ワークフロー |
| Customer tags removed | タグ削除時 | 連鎖ワークフロー |
| Customer account enabled | アカウント有効化時 | 初回ログイン施策 |
| Customer payment method created | 支払い方法追加時 | サブスクリプション準備 |

### 商品・在庫（Product / Inventory）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Product created | 商品作成時 | 自動カテゴリ分類 |
| Product status updated | 商品ステータス変更時 | 公開/非公開管理 |
| Inventory quantity changed | 在庫数変動時 | 低在庫アラート |
| Product variant back in stock | バリエーション再入荷時 | 再入荷通知トリガー |
| Product variant out of stock | バリエーション在庫切れ時 | 非表示処理 |

### フルフィルメント（Fulfillment）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Fulfillment created | フルフィルメント作成時 | 配送開始通知 |
| Fulfillment event created | 配送イベント発生時 | 追跡ステータス更新 |

### 返品・紛争（Returns / Disputes）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Return requested | 返品リクエスト時 | 返品受付通知 |
| Return approved | 返品承認時 | 返品ラベル生成 |
| Return processed | 返品処理完了時 | 在庫戻し入れ確認 |
| Dispute created | チャージバック発生時 | 緊急アラート |

### サブスクリプション（Subscription）

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Subscription contract created | サブスク契約作成時 | サブスク開始処理 |
| Subscription billing attempt success | 課金成功時 | 継続確認 |
| Subscription billing attempt failure | 課金失敗時 | リトライ・顧客連絡 |

### B2B / Company

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Company created | 会社作成時 | B2B顧客オンボーディング |
| Company contact created | 会社連絡先作成時 | 担当者登録通知 |
| Company location created | 会社拠点作成時 | 拠点別カタログ設定 |

### その他

| トリガー | 発火タイミング | 主な用途 |
|---|---|---|
| Scheduled time | 定期実行（日次/週次/月次） | 定期レポート、棚卸し |
| Discount code created | 割引コード作成時 | 割引監視 |
| Collection created | コレクション作成時 | 自動設定 |
| Metaobject entry created | メタオブジェクト作成時 | CMS連携 |
| Workflow error occurred | ワークフローエラー時 | エラー監視・通知 |

---

## 3. アクション一覧

### タグ操作

| アクション | 対象 |
|---|---|
| Add customer tags | 顧客 |
| Remove customer tags | 顧客 |
| Add order tags | 注文 |
| Remove order tags | 注文 |
| Add product tags | 商品 |
| Remove product tags | 商品 |
| Add draft order tags | 下書き注文 |
| Remove draft order tags | 下書き注文 |

### 注文管理

| アクション | 説明 |
|---|---|
| Archive order | 注文をアーカイブ |
| Unarchive order | アーカイブ解除 |
| Cancel order | 注文キャンセル |
| Capture payment | 支払いをキャプチャ |
| Mark order as paid | 支払い済みにマーク |
| Hold fulfillment | フルフィルメントを保留 |
| Release fulfillment hold | 保留解除 |
| Move fulfillment order | フルフィルメントオーダーを移動 |
| Submit fulfillment request | フルフィルメントリクエスト送信 |

### データ操作

| アクション | 説明 |
|---|---|
| Update metafield | メタフィールドを更新 |
| Remove metafield | メタフィールドを削除 |
| Add product to collection | コレクションに商品追加 |
| Remove product from collection | コレクションから商品削除 |
| Create redirect URL | リダイレクトURL作成 |
| Delete redirect URL | リダイレクトURL削除 |

### 通知・外部連携

| アクション | 説明 | プラン制限 |
|---|---|---|
| Send internal email | 内部メール送信 | 全プラン |
| Send HTTP request | 外部APIへリクエスト | Grow以上 |
| Send Admin API request | Shopify Admin APIへリクエスト | 全プラン |
| Log output | ワークフローログに出力 | 全プラン |

### フロー制御

| アクション | 説明 |
|---|---|
| Wait | 指定時間待機（分〜日単位） |
| For each (iterate) | リスト内の各アイテムに対してループ |
| Run code | カスタムコード実行（レスポンスパース等） |
| Get order/customer/product data | データ取得（トリガー外のデータ参照） |
| Sum / Count | 集計操作 |

### 返品・B2B

| アクション | 説明 |
|---|---|
| Cancel / Close / Open return | 返品操作 |
| Reopen return | 返品再開 |
| Add catalog to company location | B2B拠点にカタログ追加 |
| Remove catalog from company location | B2B拠点からカタログ削除 |
| Send B2B access email | B2Bアクセスメール送信 |

---

## 4. 条件（Conditions）

### 構文

Flow の条件はビジュアルエディタで設定するが、内部的には Liquid ベースのロジック。

**比較演算子:**

| 演算子 | 意味 | 例 |
|---|---|---|
| `==` | 等しい | `order.totalPrice == 10000` |
| `!=` | 等しくない | `order.email != ""` |
| `>` / `<` | 大なり / 小なり | `order.totalPrice > 10000` |
| `>=` / `<=` | 以上 / 以下 | `customer.ordersCount >= 3` |
| `contains` | 含む（文字列・配列） | `product.tags contains "sale"` |

**論理演算子:**

| 演算子 | 意味 | 注意 |
|---|---|---|
| `and` | かつ | `and` は `or` より先に評価される |
| `or` | または | 括弧 `()` は使用不可 |

### 変数の命名規則

Flow では **camelCase** を使用（テーマ Liquid の snake_case とは異なる）:

```
# Flow
order.createdAt
order.totalPriceSet.shopMoney.amount
customer.ordersCount

# テーマ Liquid（参考）
order.created_at
order.total_price
customer.orders_count
```

### よく使う条件パターン

```liquid
{# 高額注文の判定 #}
{% if order.totalPriceSet.shopMoney.amount > 50000 %}

{# リピーター判定 #}
{% if customer.ordersCount >= 3 %}

{# 特定タグの存在確認 #}
{% if order.tags contains "wholesale" %}

{# 特定商品タイプの注文 #}
{% for lineItem in order.lineItems %}
  {% if lineItem.product.productType == "Subscription" %}
{% endfor %}

{# 国別の分岐 #}
{% if order.shippingAddress.countryCode == "JP" %}
```

---

## 5. Send HTTP Request（詳細）

外部APIと連携するための最重要アクション。

### 基本設定

| 項目 | 説明 |
|---|---|
| URL | エンドポイントURL |
| HTTP Method | GET / POST / PUT / PATCH / DELETE |
| Headers | リクエストヘッダー（Content-Type, Authorization 等） |
| Body | リクエストボディ（JSON等） |

### レスポンスの活用

レスポンスデータはワークフロー内で変数として利用可能:

```
sendHttpRequest.statusCode    → HTTPステータスコード
sendHttpRequest.body          → レスポンスボディ
sendHttpRequest.headers       → レスポンスヘッダー
```

複数の HTTP リクエストを使う場合は `sendHttpRequest1`, `sendHttpRequest2` と番号付き変数になる。

### エラーハンドリング

| HTTP ステータス | Flow の動作オプション |
|---|---|
| 2XX | 成功 → 次のステップへ |
| 4XX | リトライ / 失敗 / 無視 を選択可能 |
| 5XX | リトライ（最大24時間） / 失敗 / 無視 を選択可能 |

### Secrets Management

APIキーやトークンは Flow の Secrets に保存し、テンプレート構文で参照:

```
{{ secrets.my_api_key }}
{{ secrets.slack_webhook_url }}
```

- **設定場所:** Flow > Settings > Secrets
- 暗号化されて保存、ワークフロー上では難読化表示
- 一括管理: シークレットを更新すれば全ワークフローに即反映

### HTTP Request の実装例

**Slack 通知:**
```json
{
  "method": "POST",
  "url": "{{ secrets.slack_webhook_url }}",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "text": "🚨 高額注文: {{ order.name }} - ¥{{ order.totalPriceSet.shopMoney.amount }}"
  }
}
```

**外部 CRM 連携:**
```json
{
  "method": "POST",
  "url": "https://api.crm.example.com/contacts",
  "headers": {
    "Authorization": "Bearer {{ secrets.crm_api_token }}",
    "Content-Type": "application/json"
  },
  "body": {
    "email": "{{ customer.email }}",
    "name": "{{ customer.displayName }}",
    "total_spent": "{{ customer.totalSpentV2.amount }}"
  }
}
```

---

## 6. システム制限

| 項目 | 制限値 |
|---|---|
| アクティブワークフロー数 | 最大 1,000 / ストア |
| ワークフロー実行時間上限 | 36 時間 |
| トリガー | 1ワークフローにつき1つ |
| 言語 | 英語のみ（UI） |

### パフォーマンスに関する注意

- 同一トリガーに大量のワークフローを紐づけると**スロットリング**が発生する可能性
- 深くネストした条件・ループは実行遅延の原因
- 高頻度トリガー（在庫変動等）は条件で早期フィルタリングすることを推奨

---

## 7. ベストプラクティス

### 設計原則

1. **1ワークフロー = 1責務** — 複数の目的を1つのワークフローに詰め込まない
2. **条件は早い段階で** — 不要な処理を早期に打ち切る
3. **命名規則を統一** — `[カテゴリ] 目的` 形式を推奨（例: `[Order] 高リスク注文ホールド`）
4. **テンプレート活用** — 公式テンプレートをベースにカスタマイズ

### デバッグ

- **ワークフロー実行ログ** で各ステップのデータを確認可能
- **サンプルデータ** でテスト実行してから本番適用
- **Workflow error occurred** トリガーでエラー監視ワークフローを構築

### 実運用パターン

#### パターン1: 高リスク注文の自動ホールド

```
Trigger: Order risk analyzed
Condition: order.riskLevel == "HIGH"
Actions:
  1. Hold fulfillment
  2. Add order tag: "high-risk"
  3. Send internal email → 担当者に通知
```

#### パターン2: VIP 顧客の自動タグ付け

```
Trigger: Order paid
Condition: customer.ordersCount >= 5 AND order.totalPriceSet.shopMoney.amount > 10000
Actions:
  1. Add customer tag: "VIP"
  2. Send HTTP request → CRM更新
```

#### パターン3: 低在庫アラート

```
Trigger: Inventory quantity changed
Condition: inventoryItem.inventoryLevel.available <= 5
Actions:
  1. Send HTTP request → Slack通知
  2. Add product tag: "low-stock"
```

#### パターン4: 定期レポート

```
Trigger: Scheduled time (毎日 9:00 JST)
Actions:
  1. Get order data (過去24時間)
  2. Sum: 売上合計
  3. Count: 注文数
  4. Send HTTP request → Slack/メール
```

#### パターン5: 返品の自動処理

```
Trigger: Return requested
Condition: order.totalPriceSet.shopMoney.amount < 3000
Actions:
  1. Approve return (自動承認)
  2. Add order tag: "auto-return"
  3. Log output: 自動承認ログ
```

---

## 8. サードパーティ連携（コネクタ）

Flow はインストール済みアプリのアクション・トリガーを利用可能。主要な連携先:

| アプリ | 連携内容 |
|---|---|
| **Klaviyo** | メールマーケティング自動化、セグメント同期 |
| **Slack** | チャンネル通知（コネクタ or HTTP request） |
| **Google Sheets** | データ行の追加・更新 |
| **Gorgias** | サポートチケット自動作成 |
| **ShipStation** | 配送ルール自動適用 |
| **Recharge** | サブスクリプション管理 |
| **Loyalty Lion / Smile.io** | ポイント付与・ランク管理 |

---

## 9. トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| ワークフローが実行されない | トリガー条件不一致 or ワークフロー無効 | ログ確認 → 条件見直し |
| 実行が遅延する | スロットリング（高頻度トリガー） | 条件で早期フィルタ、ワークフロー統合 |
| HTTP request 失敗 | 認証エラー、URL誤り、タイムアウト | Secrets確認、エンドポイント疎通チェック |
| 36時間超えで停止 | Wait アクションの合計が長すぎる | Wait 時間短縮、ワークフロー分割 |
| タグが重複追加される | 冪等性の未考慮 | 条件に `NOT contains` を追加 |

---

## 10. 開発者向け: カスタムトリガー・アクションの作成

アプリ開発者は Flow 拡張を構築可能:

```bash
# カスタムトリガーの作成
shopify app generate extension --type flow_trigger --name my-trigger

# カスタムアクションの作成
shopify app generate extension --type flow_action --name my-action
```

- カスタムトリガー: アプリ固有のイベントを Flow に公開
- カスタムアクション: アプリ固有の処理を Flow から呼び出し可能に
- テンプレート: アプリにバンドルして Flow テンプレートを提供可能

公式ドキュメント:
- トリガー: https://shopify.dev/docs/apps/build/flow/triggers/create
- アクション: https://shopify.dev/docs/apps/build/flow/actions/create
- テンプレート: https://shopify.dev/docs/apps/build/flow/templates

---

## 11. AI 生成ワークフローのインポートエラーと解消法

AI（ChatGPT、Claude、Sidekick 等）で生成した `.flow` ファイルはインポート時にエラーになることが多い。根本原因と対処法を整理する。

### なぜ AI 生成 Flow はインポートに失敗するのか

| 原因 | 詳細 |
|---|---|
| **内部スキーマの非公開** | `.flow` ファイルの正確な JSON スキーマは Shopify が公開していない。AI は推測で生成するため、必須フィールドの欠落・型の不一致が頻発する |
| **内部 ID の欠如** | 実際のエクスポートファイルには Shopify が自動付与する内部 ID（ノード ID、ステップ ID 等）が含まれる。AI はこれらを正しく生成できない |
| **トリガー/アクション名の不一致** | AI が出力する名前（例: `order_created`）と Flow が内部で使う正式な識別子が一致しない場合がある |
| **バージョン互換性** | AI の学習データが古い場合、廃止されたフィールドや旧形式の構文が含まれる |
| **アプリ依存アクションの参照不正** | サードパーティアプリのアクションは、ストアにインストール済みのアプリの内部 ID を正確に参照する必要がある |

### エラー別の対処法

#### エラー: 「ワークフローをインポートできません」（一般的なインポート失敗）

**対処手順:**

1. **JSON バリデーション** — [JSONLint](https://jsonlint.com/) で構文チェック
   - コメント、末尾カンマ、シングルクォートは不可
   - 文字列内の未エスケープ引用符を修正
2. **エンコーディング確認** — UTF-8（BOM なし）であること
3. **ファイル拡張子** — `.flow` であること（`.json` では受け付けない場合あり）

#### エラー: トリガーやアクションが「見つかりません」

**対処手順:**

1. トリガー/アクション名が Shopify Flow の正式名と一致しているか確認
2. アプリ依存のアクション → 対象アプリがストアにインストール済みか確認
3. プラン制限の確認（Send HTTP Request は Grow 以上、カスタムアプリタスクは Plus）

#### エラー: フィールドやデータ型の不一致

**対処手順:**

1. 数値フィールドに文字列が入っていないか確認
2. 必須フィールド（`name`, `trigger`, `actions`）の存在を確認
3. 配列が期待される箇所に単一値を渡していないか確認

### 推奨ワークフロー: AI → 手動構築（最も確実）

`.flow` ファイルの直接インポートではなく、AI の出力を**設計図として使い手動で構築**するのが最も確実:

```
Step 1: AI にワークフローの設計を依頼
        → トリガー・条件・アクションの構成を自然言語 or 擬似コードで出力させる
        → .flow ファイル形式での出力は求めない

Step 2: Shopify Flow エディタで手動構築
        → AI の設計に従い、ビジュアルエディタでトリガー選択 → 条件追加 → アクション設定

Step 3: テスト
        → サンプルデータで実行 → ログ確認 → 本番有効化
```

### AI への効果的なプロンプト例

AI に `.flow` ファイルを生成させるのではなく、**構造化された手順書**を出力させる:

```
以下の Shopify Flow ワークフローを設計してください。
.flow ファイルの出力は不要です。
以下の形式で手順を出力してください:

1. トリガー: [正式なトリガー名]
2. 条件:
   - フィールド: [変数パス]
   - 演算子: [比較演算子]
   - 値: [比較値]
3. アクション（実行順）:
   - [アクション名]: [パラメータ]

目的: 注文金額が5万円以上の場合に VIP タグを付与し、Slack に通知する
```

### 既存ワークフローのコピー（ストア間移行）

ストア間でワークフローを移行する場合は、AI 生成ではなく**実際のエクスポート/インポート**を使う:

```
# エクスポート元ストア
Shopify管理画面 > Flow > ワークフロー選択 > ︙ > Export

# インポート先ストア
Shopify管理画面 > Flow > Import > .flow ファイルをアップロード
```

**注意:** エクスポートされた `.flow` ファイルでも、以下の場合にインポートが失敗する:

| 原因 | 対処 |
|---|---|
| 必要なアプリが未インストール | 先にアプリをインストール |
| メタフィールド/メタオブジェクトが未定義 | 先に定義を作成 |
| ワークフロー上限（1,000）に到達 | 不要なワークフローを削除 |
| Flow バージョンの差異 | 元ストアの Shopify を最新に更新してから再エクスポート |

### Sidekick を使った AI ワークフロー作成（公式推奨）

Shopify 公式の AI アシスタント **Sidekick** は Flow エディタ内で直接ワークフローを生成できる。外部ファイルのインポートが不要なため、スキーマ不整合の問題が発生しない:

```
Shopify管理画面 > Flow > 新規ワークフロー作成
→ Sidekick に自然言語で指示（例: "Tag orders over $500 as VIP"）
→ 生成されたワークフローを確認・修正 → 有効化
```

**Sidekick の制限:**
- 複雑な条件の組み合わせは手動調整が必要な場合がある
- 英語での指示が最も精度が高い
- 生成後は必ずレビューしてから有効化する

---

## クイックリファレンス

### 判断フローチャート

```
自動化したいタスクがある
  ↓
ノーコードで十分？ → Yes → Shopify Flow
  ↓ No
API連携が必要？ → Yes → Flow + Send HTTP Request
  ↓ No
複雑なロジック？ → Yes → Shopify Functions or カスタムアプリ
```

### よく使うワークフロー TOP 5

1. **高リスク注文の自動ホールド** — Order risk analyzed → Hold fulfillment
2. **低在庫アラート** — Inventory changed → Slack通知
3. **VIPタグ自動付与** — Order paid → customer.ordersCount チェック → タグ追加
4. **注文タグの自動分類** — Order created → 商品タイプ別タグ付け
5. **返品の自動承認** — Return requested → 金額チェック → 自動承認
