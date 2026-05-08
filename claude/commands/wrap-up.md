# /wrap-up — Session Wrap-up & Master Brain Sync

End-of-session ritual. Extract key insights from this session and push them to
Master Brain NotebookLM for persistent cross-session memory.

## When to use
- Before closing a long working session
- After implementing a significant feature or debugging a hard problem
- When you've learned something that should persist beyond session context

## Steps

```bash
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LOG_DIR="$HOME/.claude/logs"
SESSION_LOG="$LOG_DIR/session-${DATE}.md"
MASTER_BRAIN_ID="58f81c6c-6f3e-42d1-9de5-e59b8975f51c"
mkdir -p "$LOG_DIR"
```

**1. Extract session insights and write to `$SESSION_LOG`.**

Review the conversation and produce a summary in this format:

```markdown
# Session Summary — DATE TIME

Project: CURRENT_DIRECTORY_NAME

## Corrections
- [correction] Things Claude got wrong; user corrections applied
  (skip if none)

## Key Patterns
- [pattern] Successful approaches discovered this session
  (skip if none)

## Decisions
- [ai] Key architectural or implementation decisions made
  (skip if none)

## Open Issues
- [open] Unresolved items to resume next session
  (skip if none)
```

Keep the summary under 2000 characters. Skip sections with nothing to add.
If nothing meaningful happened (no corrections, no patterns, no decisions,
no open issues), output "Nothing to record." and stop.

**2. Push to Master Brain:**

```bash
nlm source add "$MASTER_BRAIN_ID" "$SESSION_LOG"
```

**3. Confirm:**

```
✅ Session summary pushed to Master Brain.
   Local: $SESSION_LOG
```

If `nlm` is unavailable or unauthenticated, save locally only and note:
```
⚠️  nlm unavailable — saved locally: $SESSION_LOG
```

## Rules
- Never fabricate events that didn't happen in the session
- Use the same domain tag as the current project (shopify / ecforce / general / etc.)
- Do not push boilerplate sessions (short Q&A with no implementation)
