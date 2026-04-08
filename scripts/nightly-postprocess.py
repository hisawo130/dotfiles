#!/usr/bin/env python3
"""
nightly-postprocess.py
~~~~~~~~~~~~~~~~~~~~~~
Reads Claude's JSON response (stdin) and applies changes to files.
Handles: memory writes, CLAUDE.md edits, growth-log observation fills.

Expected JSON input (from Claude):
{
  "memory_updates": [
    { "file": "feedback_xyz.md", "action": "create|append|replace",
      "content": "...", "old": "...(for replace)" }
  ],
  "claude_md_changes": [
    { "old": "...", "new": "..." }
  ],
  "growth_log": {
    "memory_summary": "...",
    "claude_md_changes": "...",
    "refactoring": "...",
    "observations": "..."
  },
  "refactoring_changes": [
    { "file": "hooks/foo.sh", "old": "...", "new": "..." }
  ]
}
"""

import json
import sys
from pathlib import Path

HOME       = Path.home()
DOTFILES   = HOME / "dotfiles"
MEMORY_DIR = DOTFILES / "claude" / "memory"
CLAUDE_MD  = DOTFILES / "claude" / "CLAUDE.md"
GROWTH_LOG = DOTFILES / "claude" / "scripts" / "growth-log.md"
HOOKS_DIR  = DOTFILES / "claude" / "hooks"


def read_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def apply_memory_updates(updates: list):
    for u in updates:
        path = MEMORY_DIR / u["file"]
        action = u.get("action", "create")
        content = u.get("content", "")
        if action == "create":
            if path.exists():
                print(f"  [SKIP] memory already exists: {u['file']}", file=sys.stderr)
            else:
                write_file(path, content)
                print(f"  [memory:create] {u['file']}")
        elif action == "append":
            existing = read_file(path)
            write_file(path, existing.rstrip() + "\n\n" + content)
            print(f"  [memory:append] {u['file']}")
        elif action == "replace":
            old = u.get("old", "")
            if not old:
                print(f"  [SKIP] memory replace missing 'old': {u['file']}", file=sys.stderr)
                continue
            existing = read_file(path)
            if old not in existing:
                print(f"  [SKIP] memory replace pattern not found: {u['file']}", file=sys.stderr)
                continue
            write_file(path, existing.replace(old, content, 1))
            print(f"  [memory:replace] {u['file']}")


def apply_claude_md_changes(changes: list):
    content = read_file(CLAUDE_MD)
    for c in changes:
        old = c.get("old", "")
        new = c.get("new", "")
        if not old or old not in content:
            print(f"  [SKIP] CLAUDE.md pattern not found", file=sys.stderr)
            continue
        content = content.replace(old, new, 1)
        print(f"  [CLAUDE.md] 変更適用")
    write_file(CLAUDE_MD, content)


def fill_growth_log(fills: dict):
    if not fills:
        return
    content = read_file(GROWTH_LOG)
    for key, value in fills.items():
        placeholder = f"<!-- CLAUDE_FILL: {key} -->"
        if placeholder in content:
            content = content.replace(placeholder, value or "なし")
    write_file(GROWTH_LOG, content)
    print("  [growth-log] 観察コメント記入完了")


def apply_refactoring(changes: list):
    for c in changes:
        rel = c.get("file", "")
        old = c.get("old", "")
        new = c.get("new", "")
        if not rel or not old:
            continue
        path = DOTFILES / rel
        if not path.exists():
            print(f"  [SKIP] refactoring target not found: {rel}", file=sys.stderr)
            continue
        content = read_file(path)
        if old not in content:
            print(f"  [SKIP] refactoring pattern not found: {rel}", file=sys.stderr)
            continue
        write_file(path, content.replace(old, new, 1))
        print(f"  [refactor] {rel}")


def main():
    raw = sys.stdin.read().strip()
    if not raw:
        print("  [SKIP] Claude response is empty", file=sys.stderr)
        sys.exit(0)

    # Claude sometimes wraps JSON in markdown code fences
    import re
    m = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', raw, re.DOTALL)
    if m:
        raw = m.group(1)
    else:
        # Try to find JSON object in the response
        m2 = re.search(r'\{.*\}', raw, re.DOTALL)
        if m2:
            raw = m2.group(0)

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"  [ERROR] JSON parse failed: {e}", file=sys.stderr)
        print(f"  raw: {raw[:200]}", file=sys.stderr)
        sys.exit(1)

    apply_memory_updates(data.get("memory_updates", []))
    apply_claude_md_changes(data.get("claude_md_changes", []))
    fill_growth_log(data.get("growth_log", {}))
    apply_refactoring(data.get("refactoring_changes", []))


if __name__ == "__main__":
    main()
