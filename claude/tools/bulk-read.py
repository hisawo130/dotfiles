#!/usr/bin/env python3
"""bulk-read.py — Read/search multiple files in a single call.

Usage:
  python3 bulk-read.py '{"files": ["src/a.js", "src/b.js"]}'
  python3 bulk-read.py '{"pattern": "sections/*.liquid", "grep": "schema"}'
  python3 bulk-read.py '{"pattern": "**/*.md", "action": "summary"}'

Actions:
  read     — Return file contents (default)
  summary  — Return line counts and first N lines only
  search   — Grep for pattern across files
"""

import json
import re
import sys
from pathlib import Path


def resolve_files(patterns: list[str]) -> list[Path]:
    """Resolve file paths and glob patterns."""
    files = []
    for p in patterns:
        if "*" in p or "?" in p:
            files.extend(sorted(Path(".").glob(p)))
        else:
            path = Path(p)
            if path.is_file():
                files.append(path)
    return list(dict.fromkeys(files))  # dedupe preserving order


def read_files(files: list[Path], max_lines: int = 200) -> list[dict]:
    """Read multiple files, return contents."""
    results = []
    for fp in files:
        try:
            lines = fp.read_text(encoding="utf-8").splitlines()
            content = "\n".join(lines[:max_lines])
            truncated = len(lines) > max_lines
            results.append({
                "path": str(fp),
                "lines": len(lines),
                "truncated": truncated,
                "content": content,
            })
        except Exception as e:
            results.append({"path": str(fp), "error": str(e)})
    return results


def summarize_files(files: list[Path], preview_lines: int = 5) -> list[dict]:
    """Return line counts and first N lines only."""
    results = []
    for fp in files:
        try:
            lines = fp.read_text(encoding="utf-8").splitlines()
            results.append({
                "path": str(fp),
                "lines": len(lines),
                "size_bytes": fp.stat().st_size,
                "preview": "\n".join(lines[:preview_lines]),
            })
        except Exception as e:
            results.append({"path": str(fp), "error": str(e)})
    return results


def search_files(files: list[Path], pattern: str, context: int = 1, max_results: int = 30) -> list[dict]:
    """Search for regex pattern across files."""
    results = []
    total_matches = 0
    try:
        regex = re.compile(pattern, re.IGNORECASE)
    except re.error as e:
        return [{"error": f"Invalid regex: {e}"}]

    for fp in files:
        try:
            lines = fp.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue

        file_matches = []
        for i, line in enumerate(lines):
            if regex.search(line):
                start = max(0, i - context)
                end = min(len(lines), i + context + 1)
                file_matches.append({
                    "line": i + 1,
                    "match": line.strip(),
                    "context": "\n".join(lines[start:end]),
                })
                total_matches += 1
                if total_matches >= max_results:
                    break

        if file_matches:
            results.append({"path": str(fp), "matches": file_matches})

        if total_matches >= max_results:
            break

    return results


def main():
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = json.loads(sys.stdin.read())

    action = data.get("action", "read")

    # Resolve file list
    file_patterns = data.get("files", [])
    if data.get("pattern"):
        file_patterns.append(data["pattern"])
    files = resolve_files(file_patterns)

    if not files:
        result = {"results": [], "message": "No files matched"}
    elif action == "summary":
        result = {"results": summarize_files(files, data.get("preview_lines", 5))}
    elif action == "search":
        grep = data.get("grep", "")
        if not grep:
            result = {"error": "grep pattern required for search action"}
        else:
            result = {
                "results": search_files(files, grep, data.get("context", 1), data.get("max_results", 30)),
                "files_searched": len(files),
            }
    else:  # read
        result = {"results": read_files(files, data.get("max_lines", 200))}

    result["file_count"] = len(files)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
