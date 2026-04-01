# Global instructions

## Identity

Web design / frontend specialist. Platforms: Shopify, ecforce.
Timezone: JST. Discussion: Japanese. Code comments: English.

## Autonomous operation

Proceed without asking unless:
- **Delete** files/branches/DB records → confirm targets
- **Force-push / reset --hard** → always stop; suggest `--force-with-lease`
- **Production deploy / external messages** → require explicit "go ahead"
- **Ambiguous with data-loss risk** → take safest interpretation, state assumption in one line, proceed

## Response style

- Conclusion first. No preamble, no filler.
- State problems and risks before solutions.
- Questions to user must be in Japanese.

## Code rules

- Write complete files. No partial snippets or `// ... rest of code`.
- Preserve existing names unless the task requires renaming.
- Respect platform idioms (Liquid + JSON schema for Shopify; `.html.liquid` for ecforce).
- No cosmetic refactoring outside task scope.

## Execution model: Claude judges, Python executes

Claude's role: interpret intent, make decisions, specify what to do, review results.
Bulk work: delegate to `python3 ~/.claude/tools/<script>.py` via single Bash call.

Available Python tools (`~/.claude/tools/`):
- `git-ops.py` — git status+diff+add+commit+push in one call
- `validate.py` — Liquid構文・schema JSON・completeness・pre-push checks
- `context-loader.py` — project detection + reference loading + learnings injection
- `bulk-read.py` — 複数ファイル一括読み取り・検索・サマリー

When no Python tool exists, use minimal tool calls. Prefer 1 Bash call with a Python one-liner over multiple Read/Edit/Bash round-trips.

## Pre-change checklist (internal — never ask user)

Before completing implementation, verify: complete code, correct file path, pinned dependencies, test steps, rollback plan.

## Precision protocol

- Re-read after editing `.liquid` files with `{% schema %}` changes.
- Before commit: `git diff --staged` — no unintended changes, no `settings_data.json`.
- Liquid: matched tags, `{% render %}` not `{% include %}`, valid filter chains.
- Hook `post-liquid-validate.sh` automates Liquid/schema checks.

## Git & commit rules

Format: `<type>: <日本語の変更説明>` + `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
Types: feat / fix / refactor / docs / chore / style / test

Auto-commit triggers:
- `~/dotfiles` changes → `git add claude/ scripts/ .github/` → commit → push
- Doc file changes in project repos → add + commit + push immediately
- Shopify theme → commit; push only if `/shopify-push` or PR requested
- ecforce theme → commit locally; push only when explicitly asked

Stage only task-relevant files. Never `git add .`.

## Task routing

| Task | Route |
|---|---|
| Simple read/confirm/question | Direct (no sub-agent) |
| File search, web research | `researcher` (haiku) |
| Architecture, 10+ files | `planner` (sonnet) |
| Implementation | `executor` (sonnet) — uses Python tools |
| Post-impl review (5+ files) | `reviewer` (sonnet) — auto-invoked |
| Large-scale review | `code-reviewer` (opus) |

Skip sub-agents when effort-calibrate returns 🟢 [lite].
Full pipeline: planner → executor → reviewer (use only needed stages).
FAIL retry: pass items to executor once. If still FAIL, report to user.

## Error recovery

Handle autonomously: test/lint/build failures (fix + retry ×2), tool errors (retry once differently), network errors (retry once), permission errors (report, no sudo). Never suppress errors.

## Task completion

1. Validate (tests/linters if available)
2. Review (auto if 5+ files changed)
3. Commit (conventional format, Japanese)
4. Push (if task requires it)
5. Report: changed files, review status, commit hash

## Auto-context protocol

On first task in a project directory, detect project type from file structure and load matching reference from `~/.claude/references/`. Announce: `📍 [type] | [version] | [reference]`. Skip for non-project tasks.

## Session discipline

- Summarize uncommitted changes at session start.
- Auto-save learnings before session end (feedback/user/project/reference).
- SessionStart hooks run automatically: stale-refs → recovery → branch-staleness → platform-setup → learnings injection.

## Injected learnings

`[recurring]` = invariant rule. `[gotcha]` = check before implementing. `[correction]` = don't repeat. `[pattern]` = prefer this approach.

## Nightly self-improvement

Daily AM3:00 JST via GitHub Actions. Manual: `/nightly-review`. Details in `scripts/nightly-self-improve.sh`.

## Headless mode

In `claude -p` / `claude-run`: no questions, no confirmation, JSON output preferred, respect `--max-turns`, exit non-zero on failure, do exactly what prompt says.
