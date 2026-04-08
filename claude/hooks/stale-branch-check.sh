#!/bin/bash
# stale-branch-check.sh
# SessionStart hook: fetch + auto-pull (ff-only) + 乖離レポート
# 複数PC運用前提: 起動時に常に最新化する

CWD=$(pwd)

# gitリポジトリでなければスキップ
git -C "$CWD" rev-parse --is-inside-work-tree &>/dev/null || exit 0

# リモートの最新を取得（失敗してもスキップ、ネットワークなし環境に配慮）
git -C "$CWD" fetch --quiet 2>/dev/null || true

# origin/main または origin/master を特定
MAIN=""
if git -C "$CWD" rev-parse --verify "origin/main" &>/dev/null; then
  MAIN="main"
elif git -C "$CWD" rev-parse --verify "origin/master" &>/dev/null; then
  MAIN="master"
fi

[ -z "$MAIN" ] && exit 0

BEHIND=$(git -C "$CWD" rev-list "HEAD..origin/$MAIN" --count 2>/dev/null || echo 0)

# 最新ならOK
[ "$BEHIND" -eq 0 ] && exit 0

# 未コミット変更があればpull不可 → 警告のみ
DIRTY=$(git -C "$CWD" status --porcelain 2>/dev/null | grep -v '^??')
if [ -n "$DIRTY" ]; then
  jq -n --arg b "$BEHIND" --arg m "$MAIN" \
    '{"systemMessage": ("⚠️ origin/" + $m + " より " + $b + " コミット遅れていますが、未コミット変更があるため自動pullをスキップしました。手動で git pull してください。")}'
  exit 0
fi

# fast-forward pullを試みる
PULL_OUT=$(git -C "$CWD" pull --ff-only "origin" "$MAIN" 2>&1)
PULL_EXIT=$?

if [ $PULL_EXIT -eq 0 ]; then
  PULLED=$(git -C "$CWD" rev-list "HEAD@{1}..HEAD" --count 2>/dev/null || echo "$BEHIND")
  jq -n --arg b "$PULLED" --arg m "$MAIN" \
    '{"systemMessage": ("✅ git pull 完了: origin/" + $m + " から " + $b + " コミットを取得しました。")}'
else
  # ff-only失敗 = diverged → 警告のみ（強制マージはしない）
  jq -n --arg b "$BEHIND" --arg m "$MAIN" --arg e "$PULL_OUT" \
    '{"systemMessage": ("⚠️ origin/" + $m + " より " + $b + " コミット遅れています。fast-forwardできません（ブランチが分岐しています）。手動で確認してください。\n" + $e)}'
fi

exit 0
