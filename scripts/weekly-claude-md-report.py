#!/usr/bin/env python3
"""
weekly-claude-md-report.py
~~~~~~~~~~~~~~~~~~~~~~~~~~
Appends a weekly CLAUDE.md change summary to growth-log.md.
Run every Friday at AM3:00 JST via GitHub Actions.
"""

import subprocess
import sys
from datetime import date, timedelta
from pathlib import Path

DOTFILES   = Path.home() / "dotfiles"
CLAUDE_MD  = DOTFILES / "claude" / "CLAUDE.md"
GROWTH_LOG = DOTFILES / "claude" / "scripts" / "growth-log.md"
TODAY      = date.today().isoformat()


def git_log_claude_md() -> str:
    """Get git log for CLAUDE.md over the past 7 days."""
    since = (date.today() - timedelta(days=7)).isoformat()
    result = subprocess.run(
        ["git", "-C", str(DOTFILES), "log",
         f"--since={since}", "--oneline",
         "--", "claude/CLAUDE.md"],
        capture_output=True, text=True
    )
    return result.stdout.strip()


def git_diff_claude_md() -> str:
    """Get unified diff of CLAUDE.md over the past 7 days."""
    since = (date.today() - timedelta(days=7)).isoformat()
    # Find the commit hash from 7 days ago
    result = subprocess.run(
        ["git", "-C", str(DOTFILES), "log",
         f"--since={since}", "--format=%H",
         "--", "claude/CLAUDE.md"],
        capture_output=True, text=True
    )
    commits = result.stdout.strip().splitlines()
    if not commits:
        return ""
    oldest = commits[-1]
    diff = subprocess.run(
        ["git", "-C", str(DOTFILES), "diff",
         f"{oldest}~1..HEAD", "--", "claude/CLAUDE.md"],
        capture_output=True, text=True
    )
    # Keep only +/- lines, cap at 40 lines
    lines = [l for l in diff.stdout.splitlines() if l.startswith(("+", "-")) and not l.startswith(("+++", "---"))]
    return "\n".join(lines[:40])


def main():
    log_lines = git_log_claude_md()
    diff_lines = git_diff_claude_md()

    if not log_lines:
        summary = "- 今週の変更なし"
    else:
        commit_count = len(log_lines.splitlines())
        summary = f"- コミット数: {commit_count} 件\n"
        if diff_lines:
            summary += "```diff\n" + diff_lines + "\n```"
        else:
            summary += "- diff 取得不可"

    entry = f"""
## {TODAY} 週次 CLAUDE.md レポート

### 今週の変更サマリー
{summary}
---
"""
    GROWTH_LOG.parent.mkdir(parents=True, exist_ok=True)
    existing = GROWTH_LOG.read_text(encoding="utf-8") if GROWTH_LOG.exists() else ""
    if f"## {TODAY} 週次" not in existing:
        with open(GROWTH_LOG, "a", encoding="utf-8") as f:
            f.write(entry)
        print(f"  [weekly-report] {TODAY} を growth-log に追記しました", file=sys.stderr)
    else:
        print(f"  [weekly-report] 本日分は既に記録済み", file=sys.stderr)


if __name__ == "__main__":
    main()
