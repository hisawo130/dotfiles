Create a labeled WIP checkpoint commit for the current state without disrupting the main branch workflow.

Steps:
1. Run `git status` — if working tree is clean, report "nothing to checkpoint" and stop
2. Run `git diff --stat` to summarize what's changed
3. Stage all tracked modifications: `git add -u`
4. Commit with message format: `chore: checkpoint — <short description of current state>`
   - Description should be derived from the diff, not generic
5. Output: commit hash + one-line summary of what was checkpointed

Use case: mid-task save point before a risky refactor, before switching branches, or when context window is running low and you want to preserve progress.

Note: This is a local commit only. Do NOT push unless explicitly asked.
