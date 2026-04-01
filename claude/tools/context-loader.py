#!/usr/bin/env python3
"""context-loader.py — Project detection + reference loading + learnings in one call.

Usage:
  python3 context-loader.py '{"cwd": "/path/to/project"}'
  echo '{"cwd": "."}' | python3 context-loader.py

Returns project type, matching reference summary, and priority learnings.
"""

import json
import os
import re
import sys
import time
from pathlib import Path

REFERENCES_DIR = Path.home() / ".claude" / "references"
LEARNINGS_DIR = Path.home() / ".claude" / "learnings"

DOMAIN_MAP = {
    "shopify-theme": {
        "markers": ["shopify.theme.toml", "config/settings_schema.json"],
        "reference": "shopify-reference.md",
        "domain": "shopify",
    },
    "shopify-app": {
        "markers": ["shopify.app.toml"],
        "reference": "shopify-custom-app-reference.md",
        "domain": "shopify",
    },
    "ecforce": {
        "markers": ["ec_force/", "layouts/ec_force/"],
        "reference": "ecforce-reference.md",
        "domain": "ecforce",
    },
}


def detect_project(cwd: str) -> dict:
    """Detect project type from file structure."""
    p = Path(cwd).resolve()

    for ptype, info in DOMAIN_MAP.items():
        for marker in info["markers"]:
            check = p / marker
            if check.exists():
                return {"type": ptype, "domain": info["domain"], "reference": info["reference"]}

    # Check package.json for Shopify dependencies
    pkg = p / "package.json"
    if pkg.exists():
        try:
            content = pkg.read_text(encoding="utf-8")
            if "@shopify/" in content:
                return {"type": "shopify-app", "domain": "shopify", "reference": "shopify-custom-app-reference.md"}
        except Exception:
            pass

    # Check for Flow files
    if list(p.glob("*.flow")) or list(p.glob("**/*.flow")):
        return {"type": "shopify-flow", "domain": "shopify", "reference": "shopify-flow-reference.md"}

    return {"type": "generic", "domain": "general", "reference": None}


def load_reference(ref_name: str | None, max_lines: int = 50) -> dict:
    """Load reference file, check staleness, return summary."""
    if not ref_name:
        return {"loaded": False, "stale": False, "summary": ""}

    ref_path = REFERENCES_DIR / ref_name
    if not ref_path.exists():
        return {"loaded": False, "stale": False, "summary": f"{ref_name} not found"}

    # Check staleness (14 days)
    mtime = ref_path.stat().st_mtime
    age_days = (time.time() - mtime) / 86400
    stale = age_days > 14

    # Read first N lines as summary
    try:
        lines = ref_path.read_text(encoding="utf-8").splitlines()
        summary = "\n".join(lines[:max_lines])
        if len(lines) > max_lines:
            summary += f"\n... ({len(lines) - max_lines} more lines)"
    except Exception as e:
        summary = f"Error reading: {e}"

    return {
        "loaded": True,
        "stale": stale,
        "age_days": round(age_days, 1),
        "total_lines": len(lines),
        "summary": summary,
    }


def load_learnings(domain: str) -> list[str]:
    """Extract priority learnings for a domain."""
    entries = []

    for name in [f"{domain}.md", "general.md"]:
        fpath = LEARNINGS_DIR / name
        if not fpath.exists():
            continue
        try:
            content = fpath.read_text(encoding="utf-8")
        except Exception:
            continue

        # Priority order: recurring > gotcha > correction > pattern
        for tag in ["recurring", "gotcha", "correction", "pattern"]:
            for line in content.splitlines():
                if f"[{tag}]" in line and line.strip().startswith("-"):
                    entries.append(line.strip())

    # Deduplicate and limit
    seen = set()
    unique = []
    for e in entries:
        if e not in seen:
            seen.add(e)
            unique.append(e)
    return unique[:8]


def scan_project(cwd: str) -> dict:
    """Quick scan of project structure."""
    p = Path(cwd).resolve()
    ext_counts: dict[str, int] = {}
    for f in p.rglob("*"):
        if f.is_file() and not any(part.startswith(".") for part in f.parts):
            ext = f.suffix.lower() or "(no ext)"
            ext_counts[ext] = ext_counts.get(ext, 0) + 1

    has_tests = any((p / d).exists() for d in ["test", "tests", "spec", "__tests__"])
    has_linter = bool(list(p.glob(".eslintrc*")) or list(p.glob(".stylelintrc*")) or (p / ".rubocop.yml").exists())

    return {
        "file_counts": dict(sorted(ext_counts.items(), key=lambda x: -x[1])[:10]),
        "has_tests": has_tests,
        "has_linter": has_linter,
    }


def main():
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = json.loads(sys.stdin.read())

    cwd = data.get("cwd", ".")
    max_ref_lines = data.get("max_reference_lines", 50)
    include_ref = data.get("include_reference", True)
    include_learnings = data.get("include_learnings", True)
    include_scan = data.get("include_scan", False)

    project = detect_project(cwd)
    result = {
        "project_type": project["type"],
        "domain": project["domain"],
    }

    if include_ref:
        ref = load_reference(project["reference"], max_ref_lines)
        result["reference"] = ref

    if include_learnings:
        result["learnings"] = load_learnings(project["domain"])

    if include_scan:
        result["scan"] = scan_project(cwd)

    # Generate announce line
    ref_status = project["reference"] or "N/A"
    result["announce"] = f"📍 {project['type']} | {project['domain']} | {ref_status}"

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
