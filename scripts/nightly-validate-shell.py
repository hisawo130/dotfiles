#!/usr/bin/env python3
"""
nightly-validate-shell.py
~~~~~~~~~~~~~~~~~~~~~~~~~
Validates all shell scripts in claude/hooks/ and scripts/ using bash -n.
If shellcheck is installed, also runs it for deeper analysis.
Outputs a JSON summary for nightly-postprocess.py.
"""

import json
import subprocess
import sys
from pathlib import Path

DOTFILES = Path.home() / "dotfiles"
SEARCH_DIRS = [
    DOTFILES / "claude" / "hooks",
    DOTFILES / "scripts",
]


def run_bash_n(path: Path) -> dict | None:
    result = subprocess.run(
        ["bash", "-n", str(path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return {"file": str(path.relative_to(DOTFILES)), "error": result.stderr.strip()}
    return None


def run_shellcheck(path: Path) -> list[str]:
    try:
        result = subprocess.run(
            ["shellcheck", "-f", "gcc", str(path)],
            capture_output=True, text=True
        )
        if result.stdout.strip():
            lines = result.stdout.strip().splitlines()
            # Keep only warnings/errors (skip style notes SC2148 etc.)
            return [l for l in lines if ":warning:" in l or ":error:" in l]
        return []
    except FileNotFoundError:
        return []  # shellcheck not installed


def main():
    syntax_errors = []
    shellcheck_warnings = []
    checked = 0

    for search_dir in SEARCH_DIRS:
        if not search_dir.exists():
            continue
        for sh_file in sorted(search_dir.glob("*.sh")):
            checked += 1
            err = run_bash_n(sh_file)
            if err:
                syntax_errors.append(err)
            warnings = run_shellcheck(sh_file)
            for w in warnings:
                shellcheck_warnings.append({"file": str(sh_file.relative_to(DOTFILES)), "warning": w})

    result = {
        "checked": checked,
        "syntax_errors": syntax_errors,
        "shellcheck_warnings": shellcheck_warnings[:20],  # cap at 20
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))

    # Also print human-readable summary to stderr
    if syntax_errors:
        print(f"  [shell:ERROR] 構文エラー {len(syntax_errors)} 件", file=sys.stderr)
        for e in syntax_errors:
            print(f"    {e['file']}: {e['error']}", file=sys.stderr)
    else:
        print(f"  [shell:OK] 全 {checked} ファイル構文チェック通過", file=sys.stderr)


if __name__ == "__main__":
    main()
