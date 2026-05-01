#!/usr/bin/env python3
"""run-task.py — Execute ad-hoc Python scripts with timeout and output capture.

Usage:
  python3 run-task.py '{"code": "print(1+1)"}'
  python3 run-task.py '{"code": "import os; print(os.listdir(\".\"))", "timeout": 60}'
  echo 'print("hello")' | python3 run-task.py

Input:
  JSON arg with "code" field, or Python code via stdin.
  Optional: {"timeout": 30, "cwd": "/path"}
"""

import json
import os
import subprocess
import sys
import tempfile
import time


MAX_TIMEOUT = 120


def main():
    # Parse config from argv or defaults
    config = {}
    if len(sys.argv) > 1:
        try:
            config = json.loads(sys.argv[1])
        except json.JSONDecodeError:
            # Treat as code string directly
            config = {"code": sys.argv[1]}

    timeout = min(config.get("timeout", 30), MAX_TIMEOUT)
    cwd = config.get("cwd", None)

    # Get code from config or stdin
    code = config.get("code", "")
    if not code:
        code = sys.stdin.read()

    if not code.strip():
        json.dump({"ok": False, "error": "No code provided"}, sys.stdout)
        print()
        return

    # Write code to temp file and execute
    tmp = None
    try:
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".py", delete=False, encoding="utf-8"
        )
        tmp.write(code)
        tmp.close()

        start = time.time()
        result = subprocess.run(
            [sys.executable, tmp.name],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=cwd,
        )
        elapsed = round(time.time() - start, 3)

        output = {
            "ok": result.returncode == 0,
            "exit_code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "elapsed": elapsed,
        }

    except subprocess.TimeoutExpired:
        output = {"ok": False, "error": f"Timeout after {timeout}s"}
    except Exception as e:
        output = {"ok": False, "error": str(e)}
    finally:
        if tmp and os.path.exists(tmp.name):
            os.unlink(tmp.name)

    json.dump(output, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
