#!/usr/bin/env python3
"""
nightly-preprocess.py
~~~~~~~~~~~~~~~~~~~~~
Reads all learnings + memory files and emits a compact JSON digest for Claude.
Claude only needs to read this digest — not the raw files — to perform Tasks 1-3.
Also fully handles Task 5 (stale dates) and Task 6 (metrics) without AI.

Output (stdout): JSON digest
Side effects:
  - Fixes stale dates in-place (Task 5)
  - Writes metrics block to growth-log.md (Task 6)
  - Appends growth-log header scaffold (Task 4 template — Claude fills observations)
"""

import json
import os
import re
import sys
from datetime import date, datetime
from pathlib import Path
from collections import defaultdict

HOME          = Path.home()
DOTFILES      = HOME / "dotfiles"
LEARNINGS_DIR = HOME / ".claude" / "learnings"
MEMORY_DIR    = HOME / "dotfiles" / "claude" / "memory"
CLAUDE_MD     = HOME / "dotfiles" / "claude" / "CLAUDE.md"
GROWTH_LOG    = HOME / "dotfiles" / "claude" / "scripts" / "growth-log.md"
TODAY         = date.today().isoformat()
CUTOFF_DAYS   = 30

# ── helpers ──────────────────────────────────────────────────────────────────

def read_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""

def write_file(path: Path, content: str):
    path.write_text(content, encoding="utf-8")

# ── TASK 6: metrics (pure computation) ───────────────────────────────────────

TAG_RE = re.compile(r'\[(gotcha|recurring|pattern|correction|open|tip)\]')
DATE_HEADER_RE = re.compile(r'^## (\d{4}-\d{2}-\d{2})', re.MULTILINE)

def compute_metrics() -> dict:
    metrics = {}
    for f in sorted(LEARNINGS_DIR.glob("*.md")):
        content = read_file(f)
        if not content.strip():
            continue
        domain = f.stem
        tags = TAG_RE.findall(content)
        tag_counts = defaultdict(int)
        for t in tags:
            tag_counts[t] += 1
        dates = DATE_HEADER_RE.findall(content)
        last_updated = max(dates) if dates else "—"
        metrics[domain] = {
            "total": len(tags),
            "gotcha": tag_counts.get("gotcha", 0),
            "recurring": tag_counts.get("recurring", 0),
            "pattern": tag_counts.get("pattern", 0),
            "correction": tag_counts.get("correction", 0),
            "open": tag_counts.get("open", 0),
            "last_updated": last_updated,
        }
    return metrics

def metrics_to_table(metrics: dict) -> str:
    rows = []
    empty_domains = []
    for domain, m in sorted(metrics.items()):
        if m["total"] == 0:
            empty_domains.append(domain)
            continue
        rows.append(
            f"| {domain} | {m['total']} | {m['gotcha']} | {m['recurring']} | {m['last_updated']} |"
        )
    table = "### メトリクス\n"
    table += "| ドメイン | 合計 | gotcha | recurring | 最終更新 |\n"
    table += "|---|---|---|---|---|\n"
    table += "\n".join(rows) + "\n"
    if empty_domains:
        table += f"\n未蓄積ドメイン: {', '.join(empty_domains)}\n"
    return table

# ── TASK 5: stale date patrol (pure computation) ──────────────────────────────

URGENT_MARKERS = re.compile(r'(最優先|要対応|⚠️|urgent|URGENT|TODO|期限)')
DATE_PAT = re.compile(
    r'(\d{4}[年/\-]\d{1,2}[月/\-]\d{1,2}[日]?)'
    r'|(\d{4}[年/\-]\d{1,2}[月](?!\d))'
)

def parse_jp_date(s: str) -> date | None:
    s = s.replace("年", "-").replace("月", "-").replace("日", "").replace("/", "-")
    for fmt in ("%Y-%m-%d", "%Y-%m-"):
        try:
            return datetime.strptime(s.rstrip("-"), fmt.rstrip("-")).date()
        except ValueError:
            pass
    return None

def fix_stale_dates(files: list[Path]) -> list[str]:
    """Replace urgent markers with ✅ 期限済み for past dates. Returns change log."""
    changes = []
    today = date.today()
    for f in files:
        content = read_file(f)
        lines = content.splitlines(keepends=True)
        new_lines = []
        changed = False
        for line in lines:
            if not URGENT_MARKERS.search(line):
                new_lines.append(line)
                continue
            # Find dates in this line
            dates_found = DATE_PAT.findall(line)
            flat_dates = [d or m for d, m in dates_found]
            past = any(
                (pd := parse_jp_date(ds)) is not None and pd < today
                for ds in flat_dates
            )
            if past:
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

# ── TASK 1: gotcha/correction 重複候補の検出 ─────────────────────────────────

def detect_gotcha_candidates() -> list[str]:
    """Find [gotcha]/[correction] entries that appear 2+ times across all domains."""
    from collections import Counter
    all_entries = []
    for f in sorted(LEARNINGS_DIR.glob("*.md")):
        content = read_file(f)
        domain = f.stem
        for line in content.splitlines():
            m = re.search(r'\[(gotcha|correction)\]\s+(.+)', line)
            if m:
                key = re.sub(r'\s+', ' ', m.group(2).strip())[:80]
                all_entries.append((domain, m.group(1), key))

    # Group by normalized key (first 40 chars)
    from collections import defaultdict
    grouped: dict[str, list] = defaultdict(list)
    for domain, tag, key in all_entries:
        short = key[:40]
        grouped[short].append((domain, tag, key))

    candidates = []
    for short, items in grouped.items():
        if len(items) >= 2:
            domains = list({d for d, _, _ in items})
            tag = items[0][1]
            candidates.append(
                f"[{tag} 重複 {len(items)}件] {', '.join(domains)}: \"{short}...\" → メモリルール化を検討"
            )
    return candidates


# ── Build compact digest for Claude (Tasks 1-3) ───────────────────────────────

def recent_tagged_entries(content: str, days: int = CUTOFF_DAYS) -> list[str]:
    """Extract [gotcha/correction/open] entries from recent sections."""
    sections = re.split(r'(?=^## \d{4}-\d{2}-\d{2})', content, flags=re.MULTILINE)
    cutoff = (date.today().toordinal() - days)
    results = []
    for sec in sections:
        m = re.match(r'^## (\d{4}-\d{2}-\d{2})', sec)
        if not m:
            continue
        try:
            sec_date = date.fromisoformat(m.group(1))
        except ValueError:
            continue
        if sec_date.toordinal() < cutoff:
            continue
        for line in sec.splitlines():
            if re.search(r'\[(gotcha|correction|open|recurring)\]', line):
                results.append(line.strip())
    return results

def build_digest() -> dict:
    # learnings: recent tagged entries per domain
    learnings_digest = {}
    for f in sorted(LEARNINGS_DIR.glob("*.md")):
        content = read_file(f)
        entries = recent_tagged_entries(content)
        if entries:
            learnings_digest[f.stem] = entries

    # memory: existing rules (compact — just headers + first lines)
    memory_digest = {}
    for f in sorted(Path(MEMORY_DIR).glob("*.md")):
        content = read_file(f)
        # Keep only the frontmatter + first 5 non-empty lines
        lines = [l for l in content.splitlines() if l.strip()][:8]
        memory_digest[f.name] = "\n".join(lines)

    # CLAUDE.md: last 80 lines are most relevant (rules sections)
    claude_md = read_file(CLAUDE_MD)
    claude_md_excerpt = "\n".join(claude_md.splitlines()[-80:])

    return {
        "today": TODAY,
        "learnings_recent": learnings_digest,
        "memory_existing": memory_digest,
        "claude_md_tail": claude_md_excerpt,
    }

# ── Growth log scaffold (Task 4 header) ──────────────────────────────────────

def append_growth_log_header(metrics_table: str, stale_changes: list[str]):
    """Append the scaffold for today's growth log entry. Claude will fill observations."""
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
{chr(10).join(stale_changes) if stale_changes else "- 期限切れデータなし"}

{metrics_table}
---
"""
    GROWTH_LOG.parent.mkdir(parents=True, exist_ok=True)
    existing = read_file(GROWTH_LOG)
    # Avoid duplicate entry for today
    if f"## {TODAY}" not in existing:
        with open(GROWTH_LOG, "a", encoding="utf-8") as fp:
            fp.write(header)

# ── main ─────────────────────────────────────────────────────────────────────

def main():
    # Task 5: fix stale dates
    all_files = (
        list(Path(MEMORY_DIR).glob("*.md")) +
        list(LEARNINGS_DIR.glob("*.md"))
    )
    stale_changes = fix_stale_dates(all_files)
    if stale_changes:
        print("\n".join(stale_changes), file=sys.stderr)

    # Task 6: metrics
    metrics = compute_metrics()
    metrics_table = metrics_to_table(metrics)

    # Task 4: scaffold growth log header (Claude fills in the blanks)
    append_growth_log_header(metrics_table, stale_changes)

    # Build compact digest for Claude (Tasks 1-3)
    digest = build_digest()
    digest["metrics"] = metrics
    digest["stale_changes"] = stale_changes
    digest["gotcha_candidates"] = detect_gotcha_candidates()

    print(json.dumps(digest, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
