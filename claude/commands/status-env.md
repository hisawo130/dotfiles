Show a one-screen overview of the Claude Code environment.

Run:
```
python3 ~/.claude/tools/claude-status.py
```

This gives you at-a-glance state of:
- symlink health (via dotfiles-doctor)
- dotfiles git: dirty/ahead/behind + last commit
- learnings: domain count, top-3 by size, last commit
- auto-memory entry count
- settings.local.json bloat (ephemeral permission count)
- recent sessions
- nightly batch last run

Use when opening the day, or when something feels off. Faster than
asking Claude to run 5 separate Bash commands to investigate.

Options:
- `--short` : 1-line summary (e.g. `🩺✓ | 📦clean | 📚21dom`)
- `--json`  : machine-readable report
