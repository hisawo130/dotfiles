Clean up ephemeral entries in `~/.claude/settings.local.json`.

Run dry-run first:
```
python3 ~/.claude/tools/cleanup-local-permissions.py
```

Then apply if the preview looks right:
```
python3 ~/.claude/tools/cleanup-local-permissions.py --apply
```

Removed entries:
- `/tmp/...` references (one-shot test scripts)
- Single shell keywords (`Bash(do)`, `Bash(done)`, `Bash(sh)`, etc.)
- One-shot variable assignments (`Bash(dir="$HOME/...")`)
- Concrete `cp`/`mkdir` with embedded `$variables`
- Exact duplicates

Safety:
- Backup is always written to `~/.trash/` before changes
- Aborts if removal ratio exceeds 50% (catches regex misfires)
- WebFetch / WebSearch / wildcard `:*` permissions are always preserved
