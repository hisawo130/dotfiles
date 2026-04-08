#!/bin/bash
# claude-md-review.sh
# SessionStart hook: if new [correction]/[recurring] learnings exist since last
# CLAUDE.md review, inject a compact systemMessage so Claude can update it.

LAST_REVIEW="$HOME/.claude/logs/claude-md-last-review"
LEARNINGS_DIR="$HOME/.claude/learnings"

# Default: 7 days ago if never reviewed
if [ -f "$LAST_REVIEW" ]; then
  last_date=$(cat "$LAST_REVIEW" | tr -d '[:space:]')
else
  last_date=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d 2>/dev/null || echo "2000-01-01")
fi

# Extract new correction/recurring entries since last review
new_entries=$(python3 - "$LEARNINGS_DIR" "$last_date" 2>/dev/null <<'PYEOF'
import sys, re
from pathlib import Path
from datetime import date

learnings_dir = Path(sys.argv[1])
since = sys.argv[2]
results = []

for f in sorted(learnings_dir.glob("*.md")):
    content = f.read_text(encoding="utf-8")
    sections = re.split(r'(?=^## \d{4}-\d{2}-\d{2})', content, flags=re.MULTILINE)
    for sec in sections:
        m = re.match(r'^## (\d{4}-\d{2}-\d{2})', sec)
        if not m or m.group(1) <= since:
            continue
        for line in sec.splitlines():
            if re.search(r'\[(correction|recurring)\]', line):
                results.append(f"[{f.stem}] {line.strip()}")

print('\n'.join(results[:10]))  # cap at 10 to keep message small
PYEOF
)

[ -z "$new_entries" ] && exit 0

jq -n --arg entries "$new_entries" --arg since "$last_date" \
  '{"systemMessage": ("📋 CLAUDE.md見直し候補 (" + $since + " 以降の新規学習):\n" + $entries + "\n→ 関連ルールが未反映なら claude/CLAUDE.md を最小限に更新してください。")}'
