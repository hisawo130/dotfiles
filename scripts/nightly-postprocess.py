#!/usr/bin/env python3
"""
nightly-postprocess.py
~~~~~~~~~~~~~~~~~~~~~~
Reads preprocess digest (arg 1) and shell-validate result (arg 2),
then fills in the growth log placeholders written by nightly-preprocess.py.
No Claude / AI involvement.

Usage:
  python3 nightly-postprocess.py <digest.json> <shell-validate.json>
"""

import json
import sys
from pathlib import Path

DOTFILES   = Path.home() / "dotfiles"
GROWTH_LOG = DOTFILES / "claude" / "scripts" / "growth-log.md"


def read_json(path: str) -> dict:
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as e:
        print(f"  [WARN] {path} 読み込み失敗: {e}", file=sys.stderr)
        return {}


def fill_growth_log(fills: dict[str, str]):
    if not GROWTH_LOG.exists():
        print(f"  [SKIP] growth-log.md が存在しません", file=sys.stderr)
        return
    content = GROWTH_LOG.read_text(encoding="utf-8")
    for key, value in fills.items():
        placeholder = f"<!-- CLAUDE_FILL: {key} -->"
        if placeholder in content:
            content = content.replace(placeholder, value or "なし")
    GROWTH_LOG.write_text(content, encoding="utf-8")
    print("  [growth-log] 記入完了", file=sys.stderr)


def main():
    if len(sys.argv) < 3:
        print("Usage: nightly-postprocess.py <digest.json> <shell-validate.json>", file=sys.stderr)
        sys.exit(1)

    digest   = read_json(sys.argv[1])
    shell_result = read_json(sys.argv[2])

    # ── memory_summary (TASK 1 候補リスト) ──────────────────────────────────
    candidates = digest.get("gotcha_candidates", [])
    if candidates:
        memory_summary = "\n".join(f"- {c}" for c in candidates)
    else:
        memory_summary = "- 重複エントリなし（変更不要）"

    # ── shell check summary (TASK 3) ────────────────────────────────────────
    checked  = shell_result.get("checked", 0)
    errors   = shell_result.get("syntax_errors", [])
    warnings = shell_result.get("shellcheck_warnings", [])

    if errors:
        shell_summary = "\n".join(
            f"- ❌ {e['file']}: {e['error']}" for e in errors
        )
    elif warnings:
        shell_summary = (
            f"- 構文エラーなし（全 {checked} ファイル）\n"
            + "\n".join(f"- ⚠️ {w['file']}: {w['warning']}" for w in warnings[:5])
        )
    else:
        shell_summary = f"- 問題なし（全 {checked} ファイル OK）"

    # ── stale date changes (TASK 5) ──────────────────────────────────────────
    stale = digest.get("stale_changes", [])
    stale_summary = "\n".join(stale) if stale else "- 期限切れデータなし"

    fill_growth_log({
        "memory_summary":   memory_summary,
        "claude_md_changes": "スキップ（人間が手動更新）",
        "refactoring":       shell_summary,
        "observations":      "（AIなし実行 — 観察コメントなし）",
    })

    # Update stale section too (already written by preprocess, but placeholder may remain)
    content = GROWTH_LOG.read_text(encoding="utf-8")
    stale_placeholder = "<!-- CLAUDE_FILL: stale -->"
    if stale_placeholder in content:
        GROWTH_LOG.write_text(content.replace(stale_placeholder, stale_summary), encoding="utf-8")


if __name__ == "__main__":
    main()
