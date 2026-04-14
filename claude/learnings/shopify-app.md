# Shopify App Learnings
<!-- domain: shopify-app — カスタムアプリ・Storefront API・Functions・GraphQL -->

## 2026-03-26 | Shopifyアプリ
- [gotcha] ⚠️ アプリ再インストール中はWebhookが中断される。既存トークン使用コードは新トークンへの差し替えが必要

## 2026-04-14 | pietro-onlineshop_dev
- [gotcha] pietro-appデプロイ: Partner DashboardでアプリをDeleteすると既存のdiscountAutomaticAppも消える。再デプロイ後にGraphiQLでdiscountAutomaticAppCreateを再実行しないとFunction（shipping-discount）が動作しない。GraphiQL Appはwrite_discountsスコープが必須。
