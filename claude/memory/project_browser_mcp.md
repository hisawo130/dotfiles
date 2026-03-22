---
name: browser MCP 選定記録
description: Claude Codeのブラウザ自動化MCP選定経緯と将来の移行候補
type: project
---

現在の構成: `@playwright/mcp@latest`（--headlessモード）を `settings.json` の mcpServers に設定済み。dotfiles 経由で全PC同期。

**Why:** 日常的な情報取得・スクリーンショット用途では十分。npx で追加インストール不要。

**How to apply:** ブラウザ関連タスクでは playwright MCP が使用可能。再設定は不要。

---

## 移行候補: browser-use CLI

URL: https://docs.browser-use.com/open-source/browser-use-cli

`@playwright/mcp` より優れる点:
- 常駐デーモンによる50msレスポンス（vs 都度起動）
- ログインセッションの永続化
- 複数タブ・並行セッション管理
- Cookie管理・Python スクリプティング
- クラウドブラウザ対応

移行コスト: Python 3.11+ 必要、curl インストール、`--mcp` フラグで MCP サーバーとして起動

**移行タイミングの目安:** ログインが必要なページの繰り返し操作や複数セッション並行が必要になったとき。
