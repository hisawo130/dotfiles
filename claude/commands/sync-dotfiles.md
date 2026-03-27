Sync changes in ~/dotfiles/claude/ and push to remote.

Steps:
1. `git -C ~/dotfiles status` — confirm what has changed
2. `git -C ~/dotfiles diff -- claude/` — review the diff
3. Stage only claude/ directory: `git -C ~/dotfiles add claude/`
4. Commit: `git -C ~/dotfiles commit -m "chore: Claude設定更新"`
5. Push: `git -C ~/dotfiles push`
6. Report what was synced

Note: ~/.claude/CLAUDE.md, settings.json, agents/, hooks/, learnings/ are all symlinked to dotfiles — edits there are already in dotfiles.
