---
name: feedback_platform_routing
description: ecforceとShopifyのリファレンス・Liquid記法を絶対に混在させない
type: feedback
---

ecforceとShopifyは両者ともLiquidテンプレートエンジンを使用するが、記法が異なるため混在すると動作しない。

**Why:** 同じLiquid名を使っているため混乱が起きやすい。特にアセットURL記法・パーシャル読み込み・スキーマの有無が根本的に異なる。

**How to apply:**

1. **参照ファイルの分離**: タスク開始時に `<!-- PLATFORM: ... -->` コメントでファイルが正しいプラットフォームのものか確認する。ecforceタスク中にShopifyファイルを開かない（逆も同様）。

2. **記法の混在を防ぐチェックリスト:**
   - ecforceコードに `| asset_url` や `{% render %}` や `{% schema %}` があれば誤り
   - Shopifyコードに `file_root_path` や `javascript_include_tag` や `shop_shared_tag` があれば誤り
   - ecforceに `+smartphone` バリアントが必要なのにデスクトップ版のみ書いたら不完全

3. **完了前の確認**: コードを書いたらPLATFORMタグと照合して記法が正しいプラットフォームのものか確認する。
