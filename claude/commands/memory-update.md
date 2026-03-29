Manually trigger memory consolidation — same as TASK 1 of the nightly review, but run mid-session.
Use this when you want to save important learnings from the current session without waiting for AM3:00.

Steps:
1. Review the current session context:
   - What corrections did the user make?
   - What gotchas or traps were encountered?
   - What new platform-specific patterns were discovered?
   - What external resource URLs were found?
2. For each insight, classify and route:
   - User correction / preference → `claude/memory/feedback_*.md` (create new or append)
   - Platform-specific trap → `claude/learnings/<domain>.md` with `[gotcha]` tag
   - Reusable pattern → `claude/learnings/<domain>.md` with `[pattern]` tag
   - External URL / reference → `claude/memory/reference_*.md`
   - Project-specific fact → `claude/memory/project_*.md`
3. Write to the appropriate files using exact format:

   In learnings files:
   ```
   ## YYYY-MM-DD HH:MM | project-name
   - [gotcha] ...
   - [pattern] ...
   ```

   In memory/feedback files (YAML frontmatter + body):
   ```yaml
   ---
   name: feedback_<topic>
   description: <one-line summary>
   type: feedback
   ---
   <body>
   ```

4. Update `claude/memory/MEMORY.md` index if a new memory file was created
5. Run `/sync-dotfiles` to commit all changes
6. Report what was saved and where (file paths + entry count)

Note: The Stop hook (`save-learnings.sh`) also auto-captures learnings at session end.
Use `/memory-update` for important insights you want saved immediately.
