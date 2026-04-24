#!/usr/bin/env python3
"""
claude-status — Claude Code 環境の包括ステータス診断

dotfiles-doctor が症状レベルの健康診断なのに対し、こちらは
"今日どこまで何が動いてるか" を 1 画面で俯瞰する。

表示項目:
  - symlink 健全性（doctor の結果を呼び出し）
  - dotfiles repo: clean/ahead/behind/uncommitted
  - 最終の learnings コミット・最大学習ログのサイズ
  - memory/MEMORY.md エントリ数
  - settings.local.json 肥大度（使い捨て permission の数）
  - 直近 5 件のセッション (transcript)
  - 夜間バッチ最終実行

Usage:
  claude-status.py              # 標準レポート
  claude-status.py --short      # 2〜3行要約
  claude-status.py --json       # 機械可読
"""
from __future__ import annotations
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HOME = Path.home()
DOTFILES = HOME / "dotfiles"
CLAUDE = HOME / ".claude"
TOOLS = DOTFILES / "claude/tools"

# 使い捨て permission と見なす正規表現
EPHEMERAL_PERM = re.compile(
    r"(/tmp/|test-hook|test-highrisk|test-post-liquid|test-devnull)"
)


def sh(args: list[str], cwd: Path | None = None, timeout: int = 5) -> str:
    try:
        r = subprocess.run(
            args, capture_output=True, text=True,
            timeout=timeout, cwd=cwd,
        )
        return r.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return ""


def doctor_brief() -> dict:
    """dotfiles-doctor を --json モードで呼ぶ。"""
    doctor = TOOLS / "dotfiles-doctor.py"
    if not doctor.exists():
        return {"error": "doctor not found"}
    out = sh(["python3", str(doctor), "--check", "--json"])
    if not out:
        return {"ok": True}
    try:
        d = json.loads(out)
        problems = d.get("problems", [])
        fixed = d.get("fixed", [])
        return {"ok": not problems, "problems": len(problems), "fixed": len(fixed)}
    except json.JSONDecodeError:
        return {"ok": True}


def git_state() -> dict:
    if not (DOTFILES / ".git").exists():
        return {"error": "not a repo"}
    porcelain = sh(["git", "-C", str(DOTFILES), "status", "--porcelain"])
    branch = sh(["git", "-C", str(DOTFILES), "rev-parse", "--abbrev-ref", "HEAD"])
    # 上流との差分
    upstream = sh(["git", "-C", str(DOTFILES), "rev-list", "--left-right", "--count", "HEAD...@{u}"])
    ahead = behind = 0
    if upstream and "\t" in upstream:
        parts = upstream.split("\t")
        try:
            ahead, behind = int(parts[0]), int(parts[1])
        except (ValueError, IndexError):
            pass
    last_commit = sh(["git", "-C", str(DOTFILES), "log", "-1", "--format=%h %s (%cr)"])
    return {
        "branch": branch,
        "dirty_count": len([l for l in porcelain.splitlines() if l.strip()]),
        "ahead": ahead,
        "behind": behind,
        "last_commit": last_commit,
    }


def learnings_summary() -> dict:
    learnings = DOTFILES / "claude/learnings"
    if not learnings.is_dir():
        return {"error": "not found"}
    files = sorted(learnings.glob("*.md"), key=lambda p: p.stat().st_size, reverse=True)
    top = []
    for f in files[:3]:
        size = f.stat().st_size
        mtime = datetime.fromtimestamp(f.stat().st_mtime).strftime("%m-%d %H:%M")
        top.append({"name": f.name, "size": size, "mtime": mtime})
    # 最後の learnings commit
    last_learning = sh([
        "git", "-C", str(DOTFILES), "log", "-1", "--format=%cr|%s",
        "--", "claude/learnings/",
    ])
    return {
        "count": len(files),
        "top": top,
        "last_commit": last_learning,
    }


def memory_summary() -> dict:
    mem_idx = HOME / ".claude/projects/-Users-P130/memory/MEMORY.md"
    if not mem_idx.exists():
        return {"error": "MEMORY.md missing"}
    content = mem_idx.read_text()
    # エントリ行数（- で始まる）
    entries = len([l for l in content.splitlines() if l.strip().startswith("- [")])
    return {
        "entries": entries,
        "size": mem_idx.stat().st_size,
        "mtime": datetime.fromtimestamp(mem_idx.stat().st_mtime).strftime("%Y-%m-%d"),
    }


def local_settings_bloat() -> dict:
    p = CLAUDE / "settings.local.json"
    if not p.exists():
        return {"total": 0, "ephemeral": 0}
    try:
        d = json.loads(p.read_text())
    except json.JSONDecodeError:
        return {"error": "invalid JSON"}
    allow = d.get("permissions", {}).get("allow", [])
    ephemeral = [x for x in allow if EPHEMERAL_PERM.search(x)]
    return {
        "total": len(allow),
        "ephemeral": len(ephemeral),
        "ephemeral_samples": ephemeral[:3],
    }


def recent_sessions() -> list[dict]:
    projects = CLAUDE / "projects"
    if not projects.is_dir():
        return []
    sessions = []
    for jsonl in projects.rglob("*.jsonl"):
        try:
            st = jsonl.stat()
            sessions.append({
                "project": jsonl.parent.name,
                "session": jsonl.stem[:8],
                "size_kb": st.st_size // 1024,
                "mtime": datetime.fromtimestamp(st.st_mtime),
            })
        except FileNotFoundError:
            continue
    sessions.sort(key=lambda s: s["mtime"], reverse=True)
    return sessions[:5]


def nightly_log() -> dict:
    log = CLAUDE / "logs/nightly.log"
    if not log.exists():
        return {"error": "no log"}
    # 最後の "nightly-self-improve" 行を探す
    try:
        tail = log.read_text(errors="replace").splitlines()[-200:]
    except Exception:
        return {"error": "read failed"}
    last_run = ""
    for line in reversed(tail):
        if "nightly-self-improve" in line or "self-improve" in line:
            last_run = line.strip()
            break
    return {
        "mtime": datetime.fromtimestamp(log.stat().st_mtime).strftime("%Y-%m-%d %H:%M"),
        "last_run": last_run[:80],
    }


def collect() -> dict:
    return {
        "doctor": doctor_brief(),
        "git": git_state(),
        "learnings": learnings_summary(),
        "memory": memory_summary(),
        "local_settings": local_settings_bloat(),
        "sessions": recent_sessions(),
        "nightly": nightly_log(),
    }


def fmt(r: dict) -> str:
    lines = ["━━━ Claude 環境ステータス ━━━━━━━━━━━━━━━━━━━━━━━━━━━━"]

    d = r["doctor"]
    lines.append(
        f"  🩺 symlink健全性: {'OK' if d.get('ok') else '要対処 ('+str(d.get('problems',0))+'問題)'}"
    )

    g = r["git"]
    if "error" in g:
        lines.append(f"  📦 dotfiles repo: {g['error']}")
    else:
        status = []
        if g["dirty_count"]: status.append(f"未コミット{g['dirty_count']}")
        if g["ahead"]:       status.append(f"未push+{g['ahead']}")
        if g["behind"]:      status.append(f"未pull-{g['behind']}")
        status_str = " | ".join(status) if status else "clean"
        lines.append(f"  📦 dotfiles: {g['branch']} [{status_str}]")
        lines.append(f"     └─ {g['last_commit']}")

    ln = r["learnings"]
    if "error" not in ln:
        lines.append(f"  📚 learnings: {ln['count']}ドメイン | top↓")
        for t in ln["top"]:
            lines.append(f"     └─ {t['name']:<20} {t['size']//1024}KB  ({t['mtime']})")
        if ln["last_commit"]:
            ts, msg = (ln["last_commit"].split("|", 1) + [""])[:2]
            lines.append(f"     └─ last commit: {ts} | {msg[:50]}")

    m = r["memory"]
    if "error" not in m:
        lines.append(f"  🧠 memory: {m['entries']}エントリ | {m['size']//1024}KB | updated {m['mtime']}")

    ls = r["local_settings"]
    if "error" not in ls:
        eph = ls["ephemeral"]
        flag = " ⚠ 掃除推奨" if eph >= 5 else ""
        lines.append(f"  🗑  settings.local: {ls['total']}permissions (使い捨て{eph}){flag}")

    s = r["sessions"]
    if s:
        lines.append(f"  🎬 最近のセッション ({len(s)}件):")
        for x in s[:3]:
            lines.append(f"     └─ {x['mtime'].strftime('%m-%d %H:%M')}  {x['project'][:30]:<30}  {x['size_kb']}KB")

    n = r["nightly"]
    if "error" not in n:
        lines.append(f"  🌙 nightly-log: updated {n['mtime']}")

    lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    return "\n".join(lines)


def fmt_short(r: dict) -> str:
    g, ls, ln = r["git"], r["local_settings"], r["learnings"]
    bits = []
    if r["doctor"].get("ok"): bits.append("🩺✓")
    else: bits.append(f"🩺{r['doctor'].get('problems',0)}")
    if "error" not in g:
        tag = "clean"
        if g["dirty_count"] or g["ahead"] or g["behind"]:
            tag = f"{g['dirty_count']}/+{g['ahead']}/-{g['behind']}"
        bits.append(f"📦{tag}")
    if "error" not in ln: bits.append(f"📚{ln['count']}dom")
    if "error" not in ls and ls.get("ephemeral", 0) >= 5:
        bits.append(f"🗑{ls['ephemeral']}⚠")
    return " | ".join(bits)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--short", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    r = collect()
    if args.json:
        print(json.dumps(r, indent=2, default=str))
    elif args.short:
        print(fmt_short(r))
    else:
        print(fmt(r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
