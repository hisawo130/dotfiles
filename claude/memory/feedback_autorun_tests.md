---
name: feedback_autorun_tests
description: テスト実行・テスト結果に基づく改修は自動で進めてよい（承認不要）
type: feedback
---

テスト実行およびテスト結果に基づく改修は、承認なしで自動的に進めてよい。

**Why:** ユーザーはClaude Codeの自走力を最大化したい。テスト→修正→再テストの反復ループで毎回承認を求めるのは非効率。

**How to apply:** テスト失敗時は自動的に修正→再実行（最大2回）。成功するまで自律的に動く。CLAUDE.mdのError recoveryルールとも一致。
