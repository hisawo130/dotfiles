Run the nightly self-improvement batch manually (same as the 3 AM cron job).

Executes all four improvement steps in order:
1. Learning consolidation (bash) — recurring promotion, dedup, old-entry trim
2. Memory consolidation + CLAUDE.md review (AI) — extract new memory rules, update stale instructions
3. Light refactoring (AI) — fix minor issues in hooks/agents
4. Growth log update — append today's improvement summary to `claude/scripts/growth-log.md`

Usage: /nightly-review

---

実行方法: 直接 bash を呼び出す。

```bash
bash $HOME/dotfiles/scripts/nightly-self-improve.sh
```

完了後、`~/.claude/logs/nightly.log` で結果を確認できる。

cron への登録・削除・ステータス確認:
```bash
bash $HOME/dotfiles/scripts/install-nightly-cron.sh           # AM3:00 に登録
bash $HOME/dotfiles/scripts/install-nightly-cron.sh --status  # ログ確認
bash $HOME/dotfiles/scripts/install-nightly-cron.sh --remove  # 削除
```
