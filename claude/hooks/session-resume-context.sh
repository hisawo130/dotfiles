#!/bin/bash
# session-resume-context.sh
# SessionStart hook: if previous session ended abnormally (no .session-clean),
# inject the most recent learnings entries as context.

SESSION_DIR="$HOME/.claude/projects/$(echo "$PWD" | sed 's|/|-|g')"
CLEAN_FILE="$SESSION_DIR/.session-clean"
LEARNINGS_DIR="$HOME/.claude/learnings"

# Normal exit — nothing to do
[ -f "$CLEAN_FILE" ] && exit 0

# No learnings directory — nothing to inject
[ ! -d "$LEARNINGS_DIR" ] && exit 0

# Collect recent entries from the last 3 days
recent=$(python3 - "$LEARNINGS_DIR" 2>/dev/null <<'PYEOF'
import sys, re
from pathlib import Path
from datetime import date, timedelta

learnings_dir = Path(sys.argv[1])
cutoff = (date.today() - timedelta(days=3)).isoformat()
results = []

for f in sorted(learnings_dir.glob("*.md")):
    content = f.read_text(encoding="utf-8")
    sections = re.split(r'(?=^## \d{4}-\d{2}-\d{2})', content, flags=re.MULTILINE)
    for sec in sections:
        m = re.match(r'^## (\d{4}-\d{2}-\d{2})', sec)
        if not m or m.group(1) < cutoff:
            continue
        for line in sec.splitlines():
            if re.search(r'\[(gotcha|correction|open|pattern)\]', line):
                results.append(f"[{f.stem}] {line.strip()}")

print('\n'.join(results[:8]))
PYEOF
)

[ -z "$recent" ] && exit 0

jq -n --arg entries "$recent" \
  '{"systemMessage": ("⚠️ 前回セッションが正常終了していません。直近の学習コンテキスト:\n" + $entries)}'
