# /state — Project State

プロジェクトの永続状態を表示・更新する。

## 状態ファイルの場所
`~/.claude/projects/<sanitized-cwd>/state.md`
(sanitized-cwd = PWDの`/`を`-`に置換)

## 使い方
- `/state` だけ → 現在の状態ファイルを表示（なければ「未作成」と表示）
- `/state update` → 現在のセッション内容をもとに状態を更新
- `/state clear` → 状態ファイルを削除

## 状態ファイルのフォーマット（50行以内に収める）

```markdown
# Project State
<!-- cwd: {PWD} | updated: {YYYY-MM-DD HH:MM} -->

## Focus
{現在取り組んでいる機能・タスク}

## In Progress
- [ ] {未完了タスク}
- [x] {完了済みタスク}

## Decisions
- [{date}] {選択肢A}を採用。理由: {理由}

## Known Issues
- {既知の問題点}

## Next Steps
- {次のアクション}
```

## 自動更新タイミング
Task completion protocol の最後のステップで、以下のいずれかに該当するとき自動更新:
- 新しい設計上の決定をした
- In Progress の内容が変わった
- 次のセッションで必要な文脈が生まれた
