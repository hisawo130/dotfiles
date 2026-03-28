Save the current insight or learning to the appropriate domain learnings file immediately, without waiting for the session to end.

## Usage
/capture [domain] <insight text>
/capture shopify スニペット内で{% schema %}は使えない
/capture ecforce 保存=即本番。必ずテーマ複製してから編集
/capture          ← 引数なし: 直前の会話から最重要な学びを自動抽出

## Execution steps

1. **Parse arguments**:
   - If first word matches a known domain (`shopify`, `ecforce`, `ga4-gtm`, `general`, `shopify-app`, `shopify-flow`, `matrixify`, `klaviyo`, `line`, `wordpress`, `github-actions`, `cloudflare`, `react-nextjs`, `vue-nuxt`, `stripe`), use it as domain; rest is insight text
   - If no domain arg, detect from current project structure (same logic as auto-context protocol)
   - If no insight text, extract the single most actionable learning from the current conversation

2. **Classify and tag** the insight:
   - `[gotcha]` — 罠・NG・禁止・バグ・エラーの原因
   - `[pattern]` — 正しい方法・解決策・ベストプラクティス
   - `[tip]` — コツ・ポイント・覚え書き
   - `[open]` — 未解決・要調査
   - (no tag) — general observation

3. **Format entry**:
   ```

   ## YYYY-MM-DD HH:MM | <project-dirname>
   - [tag] <insight text>
   ```

4. **Append** to `~/.claude/learnings/<domain>.md`. Create file with header if it doesn't exist.

5. **Commit and push** (each as a separate Bash call):
   ```bash
   git -C ~/dotfiles add "claude/learnings/<domain>.md"
   git -C ~/dotfiles commit -m "docs: [<domain>] 学び手動追加 (capture)"
   git -C ~/dotfiles push
   ```

6. **Report** in one line: `保存: [<domain>] <insight-summary>`

Note: This is the manual complement to the automatic `save-learnings.sh` Stop hook. Use it for high-value insights discovered mid-session that you don't want to risk losing.
