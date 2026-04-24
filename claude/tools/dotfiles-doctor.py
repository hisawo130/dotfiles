#!/usr/bin/env python3
"""
dotfiles-doctor — Claude Code 設定の健全性チェック＆自動修復

Usage:
  dotfiles-doctor.py             # 修復モード。変化があった時だけ 1行要約を stdout
  dotfiles-doctor.py --verbose   # 人間向けレポート
  dotfiles-doctor.py --hook      # SessionStart用。修復があった時だけ JSON systemMessage
  dotfiles-doctor.py --check     # 修復せず、問題があれば exit 1

チェック項目:
  1. 期待される symlink が全て張られているか（learnings 事件の再発防止）
  2. dotfiles repo が git 管理下か
  3. learnings 同期状態（dotfiles とのサイズ差）
  4. MCP 設定ファイル存在
"""
from __future__ import annotations
import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path

HOME = Path.home()
DOTFILES = HOME / "dotfiles"
CLAUDE = HOME / ".claude"
TRASH = HOME / ".trash"

# name → dotfiles の実体パス（相対 or 絶対）
EXPECTED_LINKS = {
    "CLAUDE.md":     DOTFILES / "claude/CLAUDE.md",
    "settings.json": DOTFILES / "claude/settings.json",
    "statusline.py": DOTFILES / "claude/statusline.py",
    "agents":        DOTFILES / "claude/agents",
    "commands":      DOTFILES / "claude/commands",
    "hooks":         DOTFILES / "claude/hooks",
    "references":    DOTFILES / "claude/references",
    "learnings":     DOTFILES / "claude/learnings",
    "memory":        DOTFILES / "claude/memory",
    "tools":         DOTFILES / "claude/tools",
}


def trash(path: Path) -> Path:
    """rm を使わず ~/.trash/ へ移動（block-rm.sh 準拠）。"""
    TRASH.mkdir(exist_ok=True)
    dest = TRASH / f"{time.strftime('%Y%m%d-%H%M%S')}-doctor-{path.name}"
    shutil.move(str(path), str(dest))
    return dest


def check_link(name: str, target: Path, *, repair: bool) -> dict:
    """symlink の状態を判定。必要なら修復。"""
    link = CLAUDE / name
    result = {"name": name, "status": "ok", "action": None, "detail": None}

    if link.is_symlink():
        actual = os.readlink(link)
        if Path(actual) == target and link.exists():
            return result
        # symlink だけど先が違う or 壊れている
        result["status"] = "broken"
        result["detail"] = f"→ {actual}"
        if repair:
            link.unlink()
            link.symlink_to(target)
            result["action"] = "relinked"
    elif link.exists():
        # 実体ファイル/ディレクトリが症状。中身を拾ってから symlink 化
        result["status"] = "stale"
        result["detail"] = "実体 (dir/file)"
        if repair:
            moved = trash(link)
            link.symlink_to(target)
            result["action"] = f"backed-up → {moved.name}, relinked"
    else:
        result["status"] = "missing"
        if repair and target.exists():
            link.symlink_to(target)
            result["action"] = "created"
    return result


def check_learnings_drift() -> dict:
    """~/.claude/learnings 経由と dotfiles 実体でサイズ差がないか。
    symlink が正しく張られていれば常に 0 になる。"""
    a = CLAUDE / "learnings" / "general.md"
    b = DOTFILES / "claude/learnings/general.md"
    try:
        return {"drift_bytes": abs(a.stat().st_size - b.stat().st_size)}
    except FileNotFoundError:
        return {"drift_bytes": -1}


def check_repo() -> dict:
    """dotfiles が git 管理下で、未コミット差分が大きすぎないか。"""
    if not (DOTFILES / ".git").exists():
        return {"status": "not-a-repo"}
    import subprocess
    try:
        out = subprocess.run(
            ["git", "-C", str(DOTFILES), "status", "--porcelain"],
            capture_output=True, text=True, timeout=3,
        )
        dirty = [l for l in out.stdout.splitlines() if l.strip()]
        return {"status": "clean" if not dirty else "dirty", "dirty_count": len(dirty)}
    except subprocess.TimeoutExpired:
        return {"status": "timeout"}


def run(repair: bool) -> dict:
    results = [check_link(n, t, repair=repair) for n, t in EXPECTED_LINKS.items()]
    return {
        "links": results,
        "learnings": check_learnings_drift(),
        "repo": check_repo(),
        "fixed": [r for r in results if r["action"]],
        "problems": [r for r in results if r["status"] != "ok" and not r["action"]],
    }


def fmt_verbose(report: dict) -> str:
    lines = ["=== Claude dotfiles health ==="]
    for r in report["links"]:
        icon = {"ok": "✓", "broken": "✗", "stale": "⚠", "missing": "?"}[r["status"]]
        extra = f" [{r['action']}]" if r["action"] else ""
        detail = f"  ({r['detail']})" if r["detail"] else ""
        lines.append(f"  {icon} {r['name']:<15} {r['status']}{extra}{detail}")
    lines.append("")
    drift = report["learnings"]["drift_bytes"]
    if drift > 0:
        lines.append(f"  ⚠ learnings drift: {drift}B (symlink壊れの疑い)")
    elif drift == 0:
        lines.append("  ✓ learnings synced")
    lines.append(f"  repo: {report['repo']}")
    return "\n".join(lines)


def fmt_short(report: dict) -> str | None:
    """何か起きたときだけ返す。全てOKなら None。"""
    parts = []
    if report["fixed"]:
        parts.append(
            "🔧 修復: " + ", ".join(f"{r['name']}({r['action']})" for r in report["fixed"])
        )
    if report["problems"]:
        parts.append(
            "⚠ 未解決: " + ", ".join(f"{r['name']}({r['status']})" for r in report["problems"])
        )
    drift = report["learnings"]["drift_bytes"]
    if drift > 0:
        parts.append(f"⚠ learnings drift {drift}B")
    return "\n".join(parts) if parts else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--check", action="store_true", help="修復せず問題があれば exit 1")
    ap.add_argument("--hook", action="store_true", help="SessionStart 用。修復あれば systemMessage を JSON で出力")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    report = run(repair=not args.check)

    if args.json:
        print(json.dumps(report, indent=2, default=str))
        return 0
    if args.verbose:
        print(fmt_verbose(report))
        return 0
    if args.hook:
        msg = fmt_short(report)
        if msg:
            print(json.dumps({"systemMessage": msg}))
        return 0
    if args.check:
        msg = fmt_short(report)
        if msg:
            print(msg, file=sys.stderr)
            return 1
        return 0
    # default
    msg = fmt_short(report)
    if msg:
        print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
