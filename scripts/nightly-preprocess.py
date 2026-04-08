#!/usr/bin/env python3
"""
nightly-preprocess.py
~~~~~~~~~~~~~~~~~~~~~
Reads learnings files once, then computes all outputs in a single pass:
  - Task 1: gotcha/correction duplicate candidates
  - Task 5: stale date fixes (in-place)
  - Task 6: per-domain tag metrics
  - Task 4: growth-log scaffold

Output (stdout): JSON digest
"""

import json
import re
import sys
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path

HOME          = Path.home()
DOTFILES      = HOME / "dotfiles"
LEARNINGS_DIR = HOME / ".claude" / "learnings"
MEMORY_DIR    = DOTFILES / "claude" / "memory"
GROWTH_LOG    = DOTFILES / "claude" / "scripts" / "growth-log.md"
TODAY         = date.today().isoformat()
CUTOFF_DAYS   = 30

TAG_RE         = re.compile(r'\[(gotcha|recurring|pattern|correction|open|tip)\]')
DATE_HEADER_RE = re.compile(r'^## (\d{4}-\d{2}-\d{2})', re.MULTILINE)
GOTCHA_LINE_RE = re.compile(r'\[(gotcha|correction)\]\s+(.+)')
RECENT_TAG_RE  = re.compile(r'\[(gotcha|correction|open|recurring)\]')
URGENT_RE      = re.compile(r'(最優先|要対応|⚠️|urgent|URGENT|TODO|期限)')
DATE_PAT       = re.compile(
    r'(\d{4}[年/\-]\d{1,2}[月/\-]\d{1,2}[日]?)'
    r'|(\d{4}[年/\-]\d{1,2}[月](?!\d))'
)


# ── helpers ───────────────────────────────────────────────────────────────────

def read_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""

def write_file(path: Path, content: str):
    path.write_text(content, encoding="utf-8")


# ── Single-pass learnings analysis ───────────────────────────────────────────

def analyse_learnings() -> tuple[dict, dict, list[str]]:
    """
    Read each learnings file once and return:
      metrics      — per-domain tag counts
      recent_tags  — recent (30d) tagged entries per domain
      gotcha_raw   — all (domain, tag, key) tuples for duplicate detection
    """
    cutoff = date.today().toordinal() - CUTOFF_DAYS
    metrics: dict = {}
    recent_tags: dict = {}
    gotcha_raw: list = []

    for f in sorted(LEARNINGS_DIR.glob("*.md")):
        content = read_file(f)
        if not content.strip():
            continue
        domain = f.stem

        # metrics
        tags = TAG_RE.findall(content)
        tag_counts: dict = defaultdict(int)
        for t in tags:
            tag_counts[t] += 1
        dates = DATE_HEADER_RE.findall(content)
        metrics[domain] = {
            "total": len(tags),
            "gotcha": tag_counts.get("gotcha", 0),
            "recurring": tag_counts.get("recurring", 0),
            "pattern": tag_counts.get("pattern", 0),
            "correction": tag_counts.get("correction", 0),
            "open": tag_counts.get("open", 0),
            "last_updated": max(dates) if dates else "—",
        }

        # recent tagged entries + gotcha raw
        sections = re.split(r'(?=^## \d{4}-\d{2}-\d{2})', content, flags=re.MULTILINE)
        recent: list[str] = []
        for sec in sections:
            m = re.match(r'^## (\d{4}-\d{2}-\d{2})', sec)
            if not m:
                continue
            try:
                if date.fromisoformat(m.group(1)).toordinal() < cutoff:
                    continue
            except ValueError:
                continue
            for line in sec.splitlines():
                if RECENT_TAG_RE.search(line):
                    recent.append(line.strip())
        if recent:
            recent_tags[domain] = recent

        # gotcha/correction for duplicate detection (all history, not just recent)
        for line in content.splitlines():
            gm = GOTCHA_LINE_RE.search(line)
            if gm:
                key = re.sub(r'\s+', ' ', gm.group(2).strip())[:80]
                gotcha_raw.append((domain, gm.group(1), key))

    return metrics, recent_tags, gotcha_raw


# ── TASK 1: duplicate candidate detection ────────────────────────────────────

def detect_gotcha_candidates(gotcha_raw: list) -> list[str]:
    grouped: dict = defaultdict(list)
    for domain, tag, key in gotcha_raw:
        grouped[key[:40]].append((domain, tag, key))

    return [
        f"[{items[0][1]} 重複 {len(items)}件] {', '.join({d for d,_,_ in items})}: \"{short}...\" → メモリルール化を検討"
        for short, items in grouped.items()
        if len(items) >= 2
    ]


# ── TASK 6: metrics table ─────────────────────────────────────────────────────

def metrics_to_table(metrics: dict) -> str:
    rows, empty = [], []
    for domain, m in sorted(metrics.items()):
        if m["total"] == 0:
            empty.append(domain)
        else:
            rows.append(f"| {domain} | {m['total']} | {m['gotcha']} | {m['recurring']} | {m['last_updated']} |")
    table = "### メトリクス\n| ドメイン | 合計 | gotcha | recurring | 最終更新 |\n|---|---|---|---|---|\n"
    table += "\n".join(rows) + "\n"
    if empty:
        table += f"\n未蓄積ドメイン: {', '.join(empty)}\n"
    return table


# ── TASK 5: stale date patrol ────────────────────────────────────────────────

def parse_jp_date(s: str) -> date | None:
    s = s.replace("年", "-").replace("月", "-").replace("日", "").replace("/", "-")
    for fmt in ("%Y-%m-%d", "%Y-%m-"):
        try:
            return datetime.strptime(s.rstrip("-"), fmt.rstrip("-")).date()
        except ValueError:
            pass
    return None

def fix_stale_dates(files: list[Path]) -> list[str]:
    changes = []
    today = date.today()
    for f in files:
        content = read_file(f)
        new_lines = []
        changed = False
        for line in content.splitlines(keepends=True):
            if not URGENT_RE.search(line):
                new_lines.append(line)
                continue
            flat_dates = [d or m for d, m in DATE_PAT.findall(line)]
            if any((pd := parse_jp_date(ds)) is not None and pd < today for ds in flat_dates):
                new_line = re.sub(r'(最優先|要対応|⚠️)', '✅ 期限済み', line)
                if new_line != line:
                    new_lines.append(new_line)
                    changes.append(f"  {f.name}: 期限済み変換")
                    changed = True
                    continue
            new_lines.append(line)
        if changed:
            write_file(f, "".join(new_lines))
    return changes


# ── TASK 4: growth log scaffold ───────────────────────────────────────────────

def append_growth_log_header(metrics_table: str, stale_changes: list[str]):
    stale_text = "\n".join(stale_changes) if stale_changes else "- 期限切れデータなし"
    header = f"""
## {TODAY} 夜間自己改善レポート

### 記憶整理
<!-- CLAUDE_FILL: memory_summary -->

### 自動駆動の見直し
<!-- CLAUDE_FILL: claude_md_changes -->

### リファクタリング
<!-- CLAUDE_FILL: refactoring -->

### 今日の観察
<!-- CLAUDE_FILL: observations -->

### 期限切れパトロール
{stale_text}

{metrics_table}
---
"""
    GROWTH_LOG.parent.mkdir(parents=True, exist_ok=True)
    existing = read_file(GROWTH_LOG)
    if f"## {TODAY}" not in existing:
        with open(GROWTH_LOG, "a", encoding="utf-8") as fp:
            fp.write(header)


# ── main ──────────────────────────────────────────────────────────────────────

def main():
    # Single pass over all learnings files
    metrics, recent_tags, gotcha_raw = analyse_learnings()

    # Task 5: fix stale dates (memory + learnings)
    all_files = list(Path(MEMORY_DIR).glob("*.md")) + list(LEARNINGS_DIR.glob("*.md"))
    stale_changes = fix_stale_dates(all_files)
    if stale_changes:
        print("\n".join(stale_changes), file=sys.stderr)

    # Task 6 + Task 4 scaffold
    metrics_table = metrics_to_table(metrics)
    append_growth_log_header(metrics_table, stale_changes)

    digest = {
        "today": TODAY,
        "learnings_recent": recent_tags,
        "metrics": metrics,
        "stale_changes": stale_changes,
        "gotcha_candidates": detect_gotcha_candidates(gotcha_raw),
    }
    print(json.dumps(digest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
