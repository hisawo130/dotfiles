#!/usr/bin/env python3
"""git-ops.py — Git compound operations in a single call.

Usage:
  python3 git-ops.py '{"action": "status-diff"}'
  python3 git-ops.py '{"action": "commit-push", "files": ["file1"], "message": "feat: ..."}'
  python3 git-ops.py '{"action": "safe-push", "retries": 3}'
  echo '{"action": "status-diff"}' | python3 git-ops.py

Actions:
  status-diff   — Returns status, diff (staged+unstaged), and recent log
  commit-push   — Stage files, commit, push (with retry)
  safe-push     — Push with exponential backoff retry
  stage-commit  — Stage and commit only (no push)
"""

import json
import subprocess
import sys
import time


def run(cmd: list[str], check: bool = False) -> tuple[int, str]:
    """Run a git command, return (returncode, stdout+stderr)."""
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    out = (r.stdout + r.stderr).strip()
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} failed: {out}")
    return r.returncode, out


def status_diff() -> dict:
    """Gather status, diff, and recent log in one call."""
    _, status = run(["git", "status", "--short"])
    _, diff_staged = run(["git", "diff", "--cached"])
    _, diff_unstaged = run(["git", "diff"])
    _, log = run(["git", "log", "--oneline", "-5"])
    _, branch = run(["git", "branch", "--show-current"])
    return {
        "branch": branch,
        "status": status,
        "diff_staged": diff_staged,
        "diff_unstaged": diff_unstaged,
        "log": log.splitlines(),
        "result": "ok",
    }


def safe_push(retries: int = 3) -> dict:
    """Push with exponential backoff retry."""
    _, branch = run(["git", "branch", "--show-current"])
    for attempt in range(retries + 1):
        rc, out = run(["git", "push", "-u", "origin", branch])
        if rc == 0:
            return {"result": "ok", "output": out, "attempts": attempt + 1}
        if attempt < retries:
            wait = 2 ** (attempt + 1)
            time.sleep(wait)
    return {"result": "error", "output": out, "attempts": retries + 1}


def stage_commit(files: list[str], message: str) -> dict:
    """Stage specific files and commit."""
    if not files:
        return {"result": "error", "output": "No files specified"}
    if not message:
        return {"result": "error", "output": "No commit message specified"}

    # Stage files
    rc, out = run(["git", "add"] + files)
    if rc != 0:
        return {"result": "error", "stage": "add", "output": out}

    # Check if anything staged
    rc, diff = run(["git", "diff", "--cached", "--stat"])
    if not diff.strip():
        return {"result": "noop", "output": "Nothing to commit after staging"}

    # Commit
    rc, out = run(["git", "commit", "-m", message])
    if rc != 0:
        return {"result": "error", "stage": "commit", "output": out}

    _, hash_out = run(["git", "rev-parse", "--short", "HEAD"])
    return {"result": "ok", "commit": hash_out, "output": out}


def commit_push(files: list[str], message: str, retries: int = 3) -> dict:
    """Stage, commit, and push."""
    commit_result = stage_commit(files, message)
    if commit_result["result"] != "ok":
        return commit_result

    push_result = safe_push(retries)
    return {
        "result": push_result["result"],
        "commit": commit_result.get("commit", ""),
        "push_output": push_result.get("output", ""),
        "attempts": push_result.get("attempts", 0),
    }


def main():
    # Read input from args or stdin
    if len(sys.argv) > 1:
        data = json.loads(sys.argv[1])
    else:
        data = json.loads(sys.stdin.read())

    action = data.get("action", "")

    if action == "status-diff":
        result = status_diff()
    elif action == "safe-push":
        result = safe_push(data.get("retries", 3))
    elif action == "stage-commit":
        result = stage_commit(data.get("files", []), data.get("message", ""))
    elif action == "commit-push":
        result = commit_push(
            data.get("files", []),
            data.get("message", ""),
            data.get("retries", 3),
        )
    else:
        result = {"result": "error", "output": f"Unknown action: {action}"}

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
