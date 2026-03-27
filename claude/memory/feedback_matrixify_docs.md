---
name: Matrixify タスク開始前の公式ドキュメント取得
description: Matrixify関連タスクでは必ず公式ドキュメントを先に取得してから作業すること
type: feedback
---

Matrixify に関するタスクを開始する前に、必ず公式ドキュメントを WebFetch で取得してから思考・実装すること。メモリ内のリファレンスは古い可能性があるため、出発点としてのみ使用する。

**Why:** 公式ドキュメントを事後に精査したところ、Web検索ベースの情報に複数の誤りがあった（Custom Collections デフォルト Command の誤り、料金プランの数値誤りなど）。

**How to apply:**
1. Matrixify タスクを受けたら最初に関連ドキュメントページを WebFetch で取得
2. 取得先の優先順位：
   - https://matrixify.app/documentation/（全体構成）
   - https://matrixify.app/documentation/products/（商品操作）
   - https://matrixify.app/documentation/metafields/（メタフィールド）
   - https://matrixify.app/documentation/list-of-commands-across-matrixify-sheets/（コマンド仕様）
   - タスクに関連する個別ページ
3. 取得後、メモリのリファレンスと差分があれば reference_matrixify.md を更新する
