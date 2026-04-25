#!/usr/bin/env python3
"""
session-start-orchestrator — 全 SessionStart フックを並列実行して 1 つに統合

これまで settings.json の SessionStart には 10 個のフックが順次起動していた:
  10 process spawns + sequential = 体感数百ms

このオーケストレーターは:
  - 各フックを ThreadPoolExecutor で並列起動
  - 各 stdout を JSON or プレーンテキストとして解釈
  - すべての systemMessage を 1 つにマージして出力

タイムアウトに引っかかったフックは結果を捨てて続行（フェイルソフト）。
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

HOME = Path.home()
HOOKS_DIR = HOME / ".claude/hooks"
TOOLS_DIR = HOME / ".claude/tools"

# Inline shell が長いものは別ファイル化したいが、今は移行段階なので一時的に埋め込み。
INLINE_STALE_REFS = (
    '_stale=$(find "$HOME/dotfiles/claude/references" -name \'*.md\' -mtime +14 2>/dev/null | '
    'while read -r f; do echo "$(basename "$f"): $(stat -f \'%Sm\' -t \'%Y-%m-%d\' "$f")"; done); '
    '[ -n "$_stale" ] && jq -n --arg s "$_stale" '
    '\'{"systemMessage":("⚠️ 以下のリファレンスが14日以上未更新:\\n" + $s)}\' || true'
)
INLINE_PROJECT_STATE = (
    '_sf="$HOME/.claude/projects/$(echo "$PWD" | sed \'s|/|-|g\')/state.md"; '
    '[ -f "$_sf" ] && [ -s "$_sf" ] && [ "$(wc -c < "$_sf" | tr -d \' \')" -le 2048 ] && '
    'jq -n --rawfile s "$_sf" \'{"systemMessage": ("📋 Project state loaded:\\n" + $s)}\' || true'
)

HOOKS = [
    # name, cmd, kind ('bash'=shell -c, 'exec'=direct)
    ("doctor",       ["python3", str(TOOLS_DIR / "dotfiles-doctor.py"), "--hook"], "exec"),
    ("stale-refs",   ["bash", "-c", INLINE_STALE_REFS], "exec"),
    ("project-state", ["bash", "-c", INLINE_PROJECT_STATE], "exec"),
    ("recovery",     ["bash", str(HOOKS_DIR / "recovery-detect.sh")], "exec"),
    ("shopify",      ["bash", str(HOOKS_DIR / "shopify-session-start.sh")], "exec"),
    ("ecforce",      ["bash", str(HOOKS_DIR / "ecforce-session-start.sh")], "exec"),
    ("stale-branch", ["bash", str(HOOKS_DIR / "stale-branch-check.sh")], "exec"),
    ("resume-ctx",   ["bash", str(HOOKS_DIR / "session-resume-context.sh")], "exec"),
    ("open-learn",   ["bash", str(HOOKS_DIR / "check-open-learnings.sh")], "exec"),
    ("md-review",    ["bash", str(HOOKS_DIR / "claude-md-review.sh")], "exec"),
]


def run_one(name: str, cmd: list[str], stdin_data: str, timeout: float = 5.0) -> dict:
    """1 フック実行。出力を JSON か plain として解釈して返す。"""
    started = time.monotonic()
    try:
        r = subprocess.run(
            cmd,
            input=stdin_data,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed = time.monotonic() - started
        out = r.stdout.strip()
        err = r.stderr.strip()

        if not out:
            return {"name": name, "ms": int(elapsed * 1000), "msg": None, "err": err}

        # 1 行目が JSON ならそのまま使う
        try:
            j = json.loads(out)
            if isinstance(j, dict) and "systemMessage" in j:
                return {"name": name, "ms": int(elapsed * 1000), "msg": j["systemMessage"]}
        except json.JSONDecodeError:
            pass

        # plain text 扱い
        return {"name": name, "ms": int(elapsed * 1000), "msg": out}

    except subprocess.TimeoutExpired:
        return {"name": name, "ms": int(timeout * 1000), "msg": None, "err": "timeout"}
    except Exception as e:
        return {"name": name, "ms": 0, "msg": None, "err": str(e)[:80]}


def main() -> int:
    # Claude Code が hook に渡す stdin (session_id 等を含む JSON) をそのまま転送
    try:
        stdin_data = sys.stdin.read() if not sys.stdin.isatty() else ""
    except Exception:
        stdin_data = ""

    results: list[dict] = []
    with ThreadPoolExecutor(max_workers=len(HOOKS)) as pool:
        futures = {
            pool.submit(run_one, name, cmd, stdin_data): name
            for name, cmd, _ in HOOKS
        }
        for fut in as_completed(futures):
            results.append(fut.result())

    # 並び順は元の HOOKS 順に揃える（systemMessage の順序を安定化）
    order = {name: i for i, (name, _, _) in enumerate(HOOKS)}
    results.sort(key=lambda r: order.get(r["name"], 999))

    messages = [r["msg"] for r in results if r.get("msg")]
    debug = os.environ.get("ORCHESTRATOR_DEBUG") == "1"

    if debug:
        timing = " | ".join(f"{r['name']}:{r['ms']}ms" for r in results)
        sys.stderr.write(f"[orchestrator] {timing}\n")

    if not messages:
        return 0

    combined = "\n\n".join(messages)
    print(json.dumps({"systemMessage": combined}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
