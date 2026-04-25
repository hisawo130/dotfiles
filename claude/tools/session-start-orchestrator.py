#!/usr/bin/env python3
"""
session-start-orchestrator — 全 SessionStart フックを並列実行して 1 つに統合

これまで settings.json の SessionStart には 10 個のフックが順次起動していた:
  10 process spawns + sequential = 体感数百ms

このオーケストレーターは:
  - 各フックを ThreadPoolExecutor で並列起動
  - 各 stdout を JSON or プレーンテキストとして解釈
  - すべての systemMessage を 1 つにマージして出力
  - 例外/タイムアウトを ~/.claude/logs/orchestrator-errors.log に記録（フェイルソフト）

⚠️ 新しい SessionStart フックを追加するとき:
  settings.json の SessionStart は orchestrator 1 本だけを呼んでいる。
  新規フックは settings.json ではなく、このファイル下部の HOOKS リストに追加すること。
  既存の bash フックを呼ぶなら ["bash", "/path/to/hook.sh"] 形式、
  Python ネイティブにするなら str|None を返す関数をここに書いて HOOKS に登録。

デバッグ:
  ORCHESTRATOR_DEBUG=1 で stderr に各フックのタイミングを出力
"""
from __future__ import annotations
import datetime as _dt
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Callable

HOME = Path.home()
HOOKS_DIR = HOME / ".claude/hooks"
TOOLS_DIR = HOME / ".claude/tools"
REFS_DIR = HOME / "dotfiles/claude/references"
ERROR_LOG = HOME / ".claude/logs/orchestrator-errors.log"


def log_error(name: str, kind: str, detail: str) -> None:
    """フックの失敗を 1 行追記（最大 1MB で自動ローテート）。"""
    try:
        ERROR_LOG.parent.mkdir(exist_ok=True)
        # 1MB 越えたら .old にローテート
        if ERROR_LOG.exists() and ERROR_LOG.stat().st_size > 1_048_576:
            ERROR_LOG.replace(ERROR_LOG.with_suffix(".log.old"))
        with ERROR_LOG.open("a") as f:
            ts = _dt.datetime.now().isoformat(timespec="seconds")
            f.write(f"{ts}\t{name}\t{kind}\t{detail[:200]}\n")
    except Exception:
        pass  # ログ書込失敗は静黙


# ── Native Python hooks (旧 inline shell の移植) ──────────────────────────────

def py_stale_refs() -> str | None:
    """references/ で 14 日以上更新されていない .md を列挙。"""
    if not REFS_DIR.is_dir():
        return None
    cutoff = time.time() - 14 * 86400
    stale: list[str] = []
    for f in REFS_DIR.glob("*.md"):
        try:
            mtime = f.stat().st_mtime
        except OSError:
            continue
        if mtime < cutoff:
            d = _dt.date.fromtimestamp(mtime).isoformat()
            stale.append(f"{f.name}: {d}")
    if not stale:
        return None
    return "⚠️ 以下のリファレンスが14日以上未更新:\n" + "\n".join(stale)


def py_project_state() -> str | None:
    """カレントディレクトリ別の state.md があれば読み込む（2KB上限）。"""
    cwd = Path.cwd()
    sanitized = str(cwd).replace("/", "-")
    sf = HOME / f".claude/projects/{sanitized}/state.md"
    if not sf.is_file():
        return None
    try:
        size = sf.stat().st_size
    except OSError:
        return None
    if size == 0 or size > 2048:
        return None
    try:
        body = sf.read_text(errors="replace")
    except OSError:
        return None
    return f"📋 Project state loaded:\n{body}"


HOOKS: list[tuple[str, object]] = [
    # name, callable | command-list
    # callable は str|None を返す関数。subprocess を呼ばないので bash のオーバーヘッド無し。
    ("doctor",        ["python3", str(TOOLS_DIR / "dotfiles-doctor.py"), "--hook"]),
    ("stale-refs",    py_stale_refs),
    ("project-state", py_project_state),
    ("recovery",      ["bash", str(HOOKS_DIR / "recovery-detect.sh")]),
    ("shopify",       ["bash", str(HOOKS_DIR / "shopify-session-start.sh")]),
    ("ecforce",       ["bash", str(HOOKS_DIR / "ecforce-session-start.sh")]),
    ("stale-branch",  ["bash", str(HOOKS_DIR / "stale-branch-check.sh")]),
    ("resume-ctx",    ["bash", str(HOOKS_DIR / "session-resume-context.sh")]),
    ("open-learn",    ["bash", str(HOOKS_DIR / "check-open-learnings.sh")]),
    ("md-review",     ["bash", str(HOOKS_DIR / "claude-md-review.sh")]),
]


def run_one(name: str, target: object, stdin_data: str, timeout: float = 5.0) -> dict:
    """1 フック実行。target が callable なら直接、list なら subprocess。"""
    started = time.monotonic()

    # Callable: Python ネイティブ
    if callable(target):
        try:
            msg = target()
            elapsed = time.monotonic() - started
            return {"name": name, "ms": int(elapsed * 1000), "msg": msg}
        except Exception as e:
            log_error(name, "exception", str(e))
            return {"name": name, "ms": 0, "msg": None, "err": str(e)[:80]}

    # subprocess
    try:
        r = subprocess.run(
            target,
            input=stdin_data,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        elapsed = time.monotonic() - started
        out = r.stdout.strip()
        err = r.stderr.strip()

        # 非 0 終了 + stderr あり = 本物のエラー（何も出力せず exit 0 する正常 hook と区別）
        if r.returncode != 0 and err:
            log_error(name, f"exit{r.returncode}", err)

        if not out:
            return {"name": name, "ms": int(elapsed * 1000), "msg": None, "err": err}

        try:
            j = json.loads(out)
            if isinstance(j, dict) and "systemMessage" in j:
                return {"name": name, "ms": int(elapsed * 1000), "msg": j["systemMessage"]}
        except json.JSONDecodeError:
            pass

        return {"name": name, "ms": int(elapsed * 1000), "msg": out}

    except subprocess.TimeoutExpired:
        log_error(name, "timeout", f"exceeded {timeout}s")
        return {"name": name, "ms": int(timeout * 1000), "msg": None, "err": "timeout"}
    except Exception as e:
        log_error(name, "exception", str(e))
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
            pool.submit(run_one, name, target, stdin_data): name
            for name, target in HOOKS
        }
        for fut in as_completed(futures):
            results.append(fut.result())

    # 並び順は元の HOOKS 順に揃える（systemMessage の順序を安定化）
    order = {name: i for i, (name, _) in enumerate(HOOKS)}
    results.sort(key=lambda r: order.get(r["name"], 999))

    messages = [r["msg"] for r in results if r.get("msg")]
    debug = os.environ.get("ORCHESTRATOR_DEBUG") == "1"

    if debug:
        timing = " | ".join(f"{r['name']}:{r['ms']}ms" for r in results)
        sys.stderr.write(f"[orchestrator] {timing}\n")

    # statusline 用に短ステータスを cache へ書く（doctor 結果から判定）
    try:
        cache_dir = HOME / ".claude/cache"
        cache_dir.mkdir(exist_ok=True)
        doctor_msg = next((r["msg"] for r in results if r["name"] == "doctor" and r.get("msg")), None)
        health = "🩺⚠" if doctor_msg else "🩺✓"
        (cache_dir / "health.txt").write_text(health)
    except Exception:
        pass

    if not messages:
        return 0

    combined = "\n\n".join(messages)
    print(json.dumps({"systemMessage": combined}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
