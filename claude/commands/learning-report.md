Generate a summary report of all accumulated learnings across all domains.

Steps:
1. Read all files in `~/.claude/learnings/` (21 domains)
2. For each domain file, count:
   - Total entries (## headers with a date)
   - `[gotcha]` occurrences
   - `[recurring]` occurrences
   - `[pattern]` occurrences
   - `[correction]` occurrences
   - `[open]` occurrences
   - Most recent entry date (last `## YYYY-MM-DD` header)
3. List all `[recurring]` items across all domains (consolidated highest-priority knowledge)
4. List all `[gotcha]` items per domain (domain-specific traps)
5. Identify domains with 0 entries (not yet populated from sessions)
6. Output the report in this format:

---

## 学習レポート (YYYY-MM-DD 時点)

### ドメイン別サマリー

| ドメイン | 合計 | gotcha | recurring | pattern | correction | 最終更新 |
|---|---|---|---|---|---|---|
| shopify | 5 | 3 | 1 | 0 | 1 | 2026-03-27 |
| general | 8 | 3 | 1 | 2 | 1 | 2026-03-27 |
| ... | | | | | | |

### 全ドメイン Recurring Patterns（最優先）
- [shopify] ShopifyのCSVインポートには落とし穴が多い — seen 4 times
- ...

### ドメイン別 Gotchas
**shopify:**
- [gotcha] ...

### 未蓄積ドメイン（0 エントリ）
cloudflare, cms, ec-cube, ...

---

Note: This command reads from `~/.claude/learnings/` which is symlinked from `~/dotfiles/claude/learnings/`.
