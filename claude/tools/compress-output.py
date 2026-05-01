#!/usr/bin/env python3
"""
compress-output.py — Token-saving output compressor for Claude Code.

Applies 4 strategies from RTK/miina-proxy philosophy:
  1. Smart filter  — remove blank lines and boilerplate
  2. Deduplication — collapse repeated lines
  3. Grouping      — collapse file lists by directory
  4. Truncation    — keep head + tail of very long output

Design constraints:
  - Zero external dependencies (pure stdlib)
  - Zero network communication (no telemetry)
  - No compression on security-sensitive commands

Usage (pipe):
  git diff | python3 ~/.claude/tools/compress-output.py
  find . -name '*.js' | python3 ~/.claude/tools/compress-output.py

Usage (from Claude):
  python3 ~/.claude/tools/compress-output.py --cmd "git diff HEAD~1"
"""

import sys
import re
import subprocess
import argparse
from collections import defaultdict

# Threshold: skip compression if output is already small
MIN_LINES_TO_COMPRESS = 20

# Truncation settings
MAX_LINES = 150
KEEP_HEAD = 50
KEEP_TAIL = 30

# Commands that must NEVER be compressed (output integrity matters)
SKIP_CMD_PATTERNS = re.compile(
    r'^\s*(curl|wget|aws|gcloud|terraform|ssh|scp|rsync|docker pull|docker push'
    r'|git (push|pull|clone|fetch|remote))',
    re.IGNORECASE
)


def smart_filter(lines: list[str]) -> list[str]:
    """Remove blank lines and pure comment lines."""
    result = []
    for line in lines:
        s = line.rstrip()
        if not s:
            continue
        # Pure comment line (short) — skip
        if re.match(r'^\s*#\s*$', s) or (s.lstrip().startswith('#') and len(s) < 5):
            continue
        result.append(s)
    return result


def deduplication(lines: list[str]) -> list[str]:
    """Collapse consecutive identical lines into one with a count."""
    if not lines:
        return lines
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        count = 1
        while i + count < len(lines) and lines[i + count] == line:
            count += 1
        if count > 3:
            result.append(f"{line}  [×{count}]")
        else:
            result.extend([line] * count)
        i += count
    return result


def grouping(lines: list[str]) -> list[str]:
    """Collapse file lists into directory summaries when >10 path lines."""
    path_re = re.compile(r'^\.?/?[\w\-. ]+(/[\w\-. ]+)+(\.\w+)?$')
    path_lines = [l for l in lines if path_re.match(l.strip())]

    if len(path_lines) < 10 or len(path_lines) < len(lines) * 0.4:
        return lines  # Not mostly paths — skip grouping

    dirs: dict[str, list[str]] = defaultdict(list)
    non_paths = []

    for line in lines:
        stripped = line.strip()
        if path_re.match(stripped) and '/' in stripped:
            parts = stripped.rsplit('/', 1)
            dirs[parts[0]].append(parts[1])
        else:
            non_paths.append(line)

    result = list(non_paths)
    for d, files in sorted(dirs.items()):
        if len(files) > 3:
            sample = ', '.join(files[:3])
            result.append(f"{d}/  ({len(files)} files: {sample}, ...)")
        else:
            for f in files:
                result.append(f"{d}/{f}")
    return result


def truncation(lines: list[str]) -> list[str]:
    """Keep head + tail; replace middle with a marker."""
    if len(lines) <= MAX_LINES:
        return lines
    omitted = len(lines) - KEEP_HEAD - KEEP_TAIL
    return (
        lines[:KEEP_HEAD]
        + [f"⋮ [{omitted} lines omitted]"]
        + lines[-KEEP_TAIL:]
    )


def compress(text: str) -> tuple[str, int, int]:
    """Apply all strategies. Returns (compressed_text, original_line_count, final_line_count)."""
    lines = text.splitlines()
    orig = len(lines)

    if orig < MIN_LINES_TO_COMPRESS:
        return text, orig, orig

    lines = smart_filter(lines)
    lines = deduplication(lines)
    lines = grouping(lines)
    lines = truncation(lines)

    return '\n'.join(lines), orig, len(lines)


def main():
    parser = argparse.ArgumentParser(description='Compress command output to save tokens.')
    parser.add_argument('--cmd', help='Run this command and compress its output')
    parser.add_argument('--stats', action='store_true', help='Print compression stats to stderr')
    args = parser.parse_args()

    if args.cmd:
        if SKIP_CMD_PATTERNS.match(args.cmd):
            # Security-sensitive command — run without compression
            result = subprocess.run(args.cmd, shell=True, text=True, capture_output=True)
            sys.stdout.write(result.stdout)
            sys.stderr.write(result.stderr)
            sys.exit(result.returncode)

        result = subprocess.run(args.cmd, shell=True, text=True, capture_output=True)
        text = result.stdout
        if result.stderr:
            text = result.stderr + '\n' + text if not result.stdout else text + '\nSTDERR:\n' + result.stderr
        compressed, orig, final = compress(text)
        sys.stdout.write(compressed)
        if args.stats or True:  # always show stats when --cmd is used
            pct = int((1 - final / orig) * 100) if orig else 0
            sys.stderr.write(f"[compress-output] {orig}→{final} lines ({pct}% reduction)\n")
        sys.exit(result.returncode)
    else:
        # Pipe mode: read from stdin
        text = sys.stdin.read()
        compressed, orig, final = compress(text)
        sys.stdout.write(compressed)
        if args.stats:
            pct = int((1 - final / orig) * 100) if orig else 0
            sys.stderr.write(f"[compress-output] {orig}→{final} lines ({pct}% reduction)\n")


if __name__ == '__main__':
    main()
