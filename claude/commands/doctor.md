Check the health of Claude Code dotfiles setup.

Run:
```
python3 ~/.claude/tools/dotfiles-doctor.py --verbose
```

This checks all expected symlinks under `~/.claude/`, reports any drift
between local and dotfiles, and lists dotfiles repo status. Use this
whenever something feels off (learnings not saving, references missing,
etc.). Auto-repair runs on every SessionStart via the Claude hook — this
command is the manual verbose version.

Options:
- `--check` : no repair, exit 1 if anything is broken (useful for CI)
- `--json`  : machine-readable full report
