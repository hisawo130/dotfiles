Post-implementation review: check correctness, completeness, and risk before closing the task.

Steps:
1. Run `git diff HEAD` (or `git diff main..HEAD`) to list all changed files
2. For each changed file, verify:
   - No partial implementations (no "// TODO", "// rest of code", placeholder comments)
   - No renamed variables/classes that weren't part of the task
   - No cosmetic reformatting outside the task scope
3. Check dependencies:
   - Any new npm/gem/pip packages? Confirm versions are pinned
   - Any new Liquid tags or Shopify API calls? Confirm compatibility with theme version
4. Confirm impact scope:
   - Which pages/templates are affected?
   - Any shared CSS namespace collisions?
   - Any settings_data.json drift included unintentionally?
5. State rollback method: `git checkout HEAD~1 -- {file}` or equivalent
6. Output verdict: PASS or FAIL with specific reason

If FAIL: list blocking items only. Do not fix — stop and report.
