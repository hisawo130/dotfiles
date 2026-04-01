#!/usr/bin/env python3
"""multi-edit.py — Apply multiple find-and-replace edits across files in one call.

Usage:
  python3 multi-edit.py '{"edits": [{"file": "path", "old": "...", "new": "..."}]}'
  echo '{"edits": [...], "dry_run": true}' | python3 multi-edit.py

Options:
  edits    — List of {file, old, new} edit operations
  dry_run  — Preview changes without writing (default: false)
  backup   — Create .bak files before editing (default: true)
"""

import json
import shutil
import sys
from pathlib import Path


def apply_edits(edits: list[dict], dry_run: bool = False, backup: bool = True) -> dict:
    results = []

    for edit in edits:
        file_path = Path(edit["file"])
        old_text = edit["old"]
        new_text = edit["new"]
        entry = {"file": str(file_path)}

        if not file_path.is_file():
            entry.update(ok=False, error=f"File not found: {file_path}")
            results.append(entry)
            continue

        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception as e:
            entry.update(ok=False, error=f"Read error: {e}")
            results.append(entry)
            continue

        count = content.count(old_text)
        if count == 0:
            # Show nearby context to help debug
            snippet = old_text[:60].replace("\n", "\\n")
            entry.update(ok=False, error=f"Pattern not found: '{snippet}'")
            results.append(entry)
            continue

        new_content = content.replace(old_text, new_text)

        if dry_run:
            entry.update(ok=True, changes=count, dry_run=True)
            results.append(entry)
            continue

        # Backup before writing
        if backup:
            bak_path = file_path.with_name(file_path.name + ".multi-edit.bak")
            try:
                shutil.copy2(file_path, bak_path)
            except Exception as e:
                entry.update(ok=False, error=f"Backup failed: {e}")
                results.append(entry)
                continue

        try:
            file_path.write_text(new_content, encoding="utf-8")
            entry.update(ok=True, changes=count)
        except Exception as e:
            entry.update(ok=False, error=f"Write error: {e}")

        results.append(entry)

    ok_count = sum(1 for r in results if r.get("ok"))
    return {
        "results": results,
        "summary": f"{ok_count}/{len(results)} files edited",
    }


def main():
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = json.loads(sys.stdin.read())

    edits = data.get("edits", [])
    if not edits:
        json.dump({"results": [], "summary": "No edits specified"}, sys.stdout)
        print()
        return

    result = apply_edits(
        edits,
        dry_run=data.get("dry_run", False),
        backup=data.get("backup", True),
    )
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
