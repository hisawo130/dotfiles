# Daily Maintenance — 3:00 AM JST

Fully autonomous. No interactive prompts. Run all tasks in sequence.

```bash
git config user.email 'claude-scheduled@anthropic.com'
git config user.name 'Claude Scheduled Agent'
```

---

## TASK 1: Learnings Consolidation

Process every file in `claude/learnings/`.

### Tagging conventions
- `[gotcha]` — trap, NG, 禁止, 落とし穴, エラーの原因, してはいけない
- `[pattern]` — correct approach, best practice, 解決策, 正しい方法
- `[tip]` — コツ, ポイント, 覚え書き
- `[open]` — unresolved, 要調査, 未解決, 継続調査
- `[correction]` — user correction, 修正指示

### Per-file operations

**REMOVE** (noise / low-quality):
- Lines matching `- 作業: /Users/` (local absolute paths)
- Lines matching `- 完了: コミット \`HASH\`` with no description after the hash
- Exact duplicate lines — keep first occurrence
- Near-duplicate lines (same core fact, different phrasing in same file) — keep the better-tagged version
- `## DATE | PROJECT` block headers whose every content line was removed

**ADD** missing type tags: if a line has no tag bracket but content matches a tag's criteria, prepend the tag. Do not change content otherwise.

**CONSOLIDATE**: multiple `## DATE | SAME_PROJECT` blocks with closely related entries → merge into one block (use most recent date). Conservative: when unsure whether to delete, keep the line.

### Cross-file pattern analysis

Scan the full learnings corpus. Find concepts appearing 3+ times (use semantic matching, not just literal text). Update the `## Recurring Patterns (updated YYYY-MM-DD)` section at the bottom of `claude/learnings/general.md`:
- Create the section if absent
- Add new patterns; update counts for existing ones
- Format: `- [domain] RULE — seen N times`

### Commit

```bash
git add claude/learnings/
git diff --cached --quiet || git commit -m "chore: learnings consolidation $(date +%Y-%m-%d)"
```

Track for report: `t1_files`, `t1_removed`, `t1_tagged`, `t1_patterns`

---

## TASK 2: Shopify Changelog Update

Reference files in `claude/references/`:
- `shopify-reference.md`
- `shopify-custom-app-reference.md`
- `shopify-flow-reference.md`
- `shopify-webhooks-metafields-reference.md`
- `shopify-hydrogen-appbridge-subscriptions-reference.md`
- `shopify-theme-app-extensions-reference.md`

Read last sync from `claude/references/.shopify-changelog-last-sync` (ISO datetime). If absent, default to 7 days ago.

Fetch `https://shopify.dev/changelog/feed.xml`. Keep entries published after last sync, developer-relevant only (skip merchant/admin-facing announcements).

Classify by keywords:
- Theme / Liquid / OS2.0 / Dawn / Sections → `shopify-reference.md`
- App / API / GraphQL / REST / Functions / Remix → `shopify-custom-app-reference.md`
- Flow / automation / workflow → `shopify-flow-reference.md`
- Webhook / Metafield / Metaobject → `shopify-webhooks-metafields-reference.md`
- Hydrogen / headless / App Bridge / B2B → `shopify-hydrogen-appbridge-subscriptions-reference.md`
- Theme app extensions / checkout extensions → `shopify-theme-app-extensions-reference.md`

Add to `## 📋 Recent Changelog` section near top of each target file (create if absent):
```
### YYYY-MM-DD: [Title](url)
[1-2 sentence developer-focused summary]
```
Max 20 entries per section (remove oldest if over 20). Write newest entry's pubDate to `.shopify-changelog-last-sync`.

### Commit

```bash
git add claude/references/
git diff --cached --quiet || git commit -m "docs: shopify changelog $(date +%Y-%m-%d)"
```

Track: `t2_new`

---

## TASK 3: Dawn Theme Version Monitor

Fetch `https://api.github.com/repos/Shopify/dawn/releases/latest`. Extract `tag_name` (e.g. `v15.4.1`) and `published_at`.

Read `claude/references/.dawn-version-last-known` (last seen version). If absent: write current `tag_name` to the file, set `t3_new=false`, skip to TASK 4.

If `tag_name` differs from last-known:
1. Read `claude/references/shopify-reference.md`. Add or replace the line matching `<!-- Dawn latest:` near the top: `<!-- Dawn latest: TAG (released DATE) -->`
2. If `claude/references/shopify-dawn-reference.md` exists, apply the same replacement there
3. Write new `tag_name` to `.dawn-version-last-known`
4. Set `t3_new=true`

```bash
git add claude/references/
git diff --cached --quiet || git commit -m "docs: Dawn version update $(date +%Y-%m-%d)"
```

Track: `t3_version`, `t3_new`

---

## TASK 4: Shopify API Version Tracker

Fetch `https://shopify.dev/docs/api/usage/versioning`. Extract:
- Current stable API version (format `YYYY-MM`)
- Versions listed as deprecated or being sunset

Read `claude/references/.shopify-api-last-known`. Format:
```
stable=YYYY-MM
deprecated=YYYY-MM,YYYY-MM
```
If absent: write current state, set `t4_alert=""`, skip to TASK 5.

Compare with stored values:
- Stable version changed → `t4_alert="stable: OLD → NEW"`
- New deprecated version found → `t4_alert="deprecated added: YYYY-MM"`
- No change → `t4_alert=""`

If `t4_alert` is set: read `claude/references/shopify-custom-app-reference.md`. Add or replace the line matching `<!-- API alert` near the top: `<!-- API alert (DATE): MESSAGE -->`

Update `.shopify-api-last-known` with current values.

```bash
git add claude/references/
git diff --cached --quiet || git commit -m "docs: shopify API version update $(date +%Y-%m-%d)"
```

Track: `t4_alert`

---

## TASK 5: Reference Staleness Audit

For each `.md` file in `claude/references/`:
1. Get last commit date: `git log --follow -1 --format="%ci" -- FILEPATH`
2. Calculate days since that date
3. Check if file contains the text `UPDATE BEFORE USE`

Categories:
- **STALE**: >30 days AND has `UPDATE BEFORE USE` → needs refresh
- **AGING**: >30 days, no `UPDATE BEFORE USE` → informational
- **OK**: ≤30 days

Write results to `claude/references/.staleness-report` (overwrite each run):
```
# Reference Staleness YYYY-MM-DD
STALE: filename.md (N days)
AGING: filename.md (N days)
OK: filename.md (N days)
```

```bash
git add claude/references/.staleness-report
git diff --cached --quiet || git commit -m "chore: staleness report $(date +%Y-%m-%d)"
```

Track: `t5_stale` (comma-separated filenames), `t5_aging`

---

## TASK 6: Anthropic Repos Monitor (週次 — 日曜のみ)

Run only if today is Sunday: `[ "$(date +%u)" = "7" ] || skip to FINAL`

Check Anthropic's Claude Code repositories for new features and best practices, then apply relevant improvements to the `claude/` directory.

### Research sources (WebFetch each)

1. `https://code.claude.com/docs/llms.txt` — full docs index
2. `https://github.com/anthropics/claude-code/releases` — recent releases
3. `https://code.claude.com/docs/ja/best-practices` — best practices
4. `https://code.claude.com/docs/ja/hooks-guide` — hooks guide

### What to look for

- New hook event types not in `claude/settings.json`
- CLAUDE.md best practice changes (what to add/remove)
- New CLI flags, permission modes, or built-in features
- Deprecated patterns currently in use
- New workflow patterns applicable to Shopify/ecforce frontend work

### Review current setup

Read: `claude/CLAUDE.md`, `claude/settings.json`, all files in `claude/hooks/`, `claude/tools/`, `claude/skills/`

### Apply improvements

For each applicable finding:
- Edit only files inside `claude/`
- Keep changes minimal and targeted — no cosmetic refactoring
- Follow existing style (English code comments, Japanese commit messages)
- When uncertain, skip and note as "Considered but skipped: ..." in commit message

### Commit

```bash
git add claude/
git diff --cached --quiet || git commit -m "chore: Anthropicリポジトリ監視ブラッシュアップ $(date +%Y-%m-%d)

[list each change and its source URL]

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

Track: `t6_changes` (number of files changed, or "skipped" if not Sunday, or "no_changes")

---

## FINAL: Push + Discord

```bash
git push
```

Send Discord notification using the webhook. Build the message from all tracked variables:

```
dotfiles daily (DATE 03:00 JST)
[1] Learnings — files:N removed:N tagged:N patterns:N
[2] Changelog — new:N
[3] Dawn — VERSION (new:YES/NO)
[4] API — ALERT_OR_no_change
[5] Stale refs — STALE_LIST_OR_all_OK
[6] Anthropic monitor — CHANGES_OR_skipped_OR_no_changes
https://github.com/hisawo130/dotfiles/commits/main
```

Always send — even if all sections are clean (confirms run completed).

Webhook URL: `https://discord.com/api/webhooks/1486928286541021345/4po5j-0O5Qzdql7wBdNr0Ga0_Ian-t7P66IMj7DzHWKMuDRr9IH7OSYoHTu0S644C8E6`
