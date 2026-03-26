#!/bin/bash
# stale-branch-check.sh
# SessionStart hook: origin/main(master)との乖離を検出して警告
# ネットワーク不使用 — ローカルキャッシュ済みのリモート参照で比較

CWD=$(pwd)

# gitリポジトリでなければスキップ
git -C "$CWD" rev-parse --is-inside-work-tree &>/dev/null || exit 0

# origin/main または origin/master を特定
MAIN=""
BEHIND=0
if git -C "$CWD" rev-parse --verify "origin/main" &>/dev/null; then
  MAIN="main"
  BEHIND=$(git -C "$CWD" rev-list "HEAD..origin/main" --count 2>/dev/null || echo 0)
elif git -C "$CWD" rev-parse --verify "origin/master" &>/dev/null; then
  MAIN="master"
  BEHIND=$(git -C "$CWD" rev-list "HEAD..origin/master" --count 2>/dev/null || echo 0)
fi

# リモートブランチなし or 10コミット未満 → スキップ
[ -z "$MAIN" ] && exit 0
[ "$BEHIND" -lt 10 ] && exit 0

jq -n --arg b "$BEHIND" --arg m "$MAIN" \
  '{"systemMessage": ("⚠️ 現在のブランチは origin/" + $m + " より " + $b + " コミット遅れています。作業前に git pull を検討してください")}'
exit 0
