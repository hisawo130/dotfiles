# Claude Self-Growth Log
<!-- nightly-self-improve.sh / GitHub Actions が毎朝 AM3:00 JST に追記 -->
<!-- 手動実行: /nightly-review または bash ~/dotfiles/scripts/nightly-self-improve.sh -->

## 2026-03-28 初期化

### システム状態
- 夜間自己改善バッチ稼働開始（GitHub Actions + ローカル cron）
- 学習ファイル: 21 ドメイン（shopify, ecforce, general ほか）
- メモリファイル: 14 件（user_profile, feedback_*, reference_*, shopify_*）
- 有効フック: SessionStart (6) / Stop (2) / PreToolUse (2) / PostToolUse (3)

### メトリクス（初期）
| ドメイン | 合計 | gotcha | recurring | 最終更新 |
|---|---|---|---|---|
| shopify | 5 | 3 | 0 | 2026-03-27 |
| general | 8 | 3 | 1 | 2026-03-27 |
| matrixify | 2 | 1 | 0 | 2026-03-25 |
| ecforce | 2 | 1 | 0 | 2026-03-26 |

未蓄積ドメイン: cloudflare, cms, ec-cube, ga4-gtm, github-actions, klaviyo,
               line, make-zapier, react-nextjs, shopify-app, shopify-extensions,
               shopify-flow, shopify-hydrogen, shopify-webhooks, stripe, vue-nuxt, wordpress

## 2026-04-08 夜間自己改善レポート

### 記憶整理
- [gotcha 重複 2件] general: "pull 前に未コミット変更をチェック。ff-only でもコンフリクト時は警告..." → メモリルール化を検討

### 自動駆動の見直し
スキップ（人間が手動更新）

### リファクタリング
- 問題なし（全 0 ファイル OK）

### 今日の観察
（AIなし実行 — 観察コメントなし）

### 期限切れパトロール
  shopify_platform_updates.md: 期限済み変換
  shopify_platform_updates.md: 期限済み変換

### メトリクス
| ドメイン | 合計 | gotcha | recurring | 最終更新 |
|---|---|---|---|---|
| general | 8 | 3 | 0 | 2026-04-08 |

---

## 2026-04-08 週次 CLAUDE.md レポート

### 今週の変更サマリー
- コミット数: 2 件
```diff
+**Script-first rule:** 3+同種ツールコール（複数Read, 複数Edit等）が必要な場合、Pythonスクリプト1本にまとめる。
+- 複数ファイル編集 → `multi-edit.py`
+- アドホック複合処理 → `run-task.py`（コードをJSON渡し）
+- 単純な一回限り → `python3 -c '...'`
+
+- `multi-edit.py` — 複数ファイル一括find-and-replace（バックアップ付き）
+- `run-task.py` — アドホックPythonスクリプト実行（timeout + stderr capture）
-- Auto-save learnings before session end (feedback/user/project/reference).
-- SessionStart hooks run automatically: stale-refs → recovery → branch-staleness → platform-setup → learnings injection.
+- SessionStart/Stop hooks run automatically (pull, learnings inject/save, notify).
+
+## Compaction
+
+When compacting, always preserve:
+- List of files modified in this session
+- Current branch and any uncommitted changes summary
+- Active task description and acceptance criteria
+- Any test/build commands discovered during the session
-`[recurring]` = invariant rule. `[gotcha]` = check before implementing. `[correction]` = don't repeat. `[pattern]` = prefer this approach.
+`[recurring]` = invariant rule. `[gotcha]` = check before implementing. `[correction]` = don't repeat. `[pattern]` = prefer this approach. `[ai]` = AI-extracted (high confidence).
```
---
