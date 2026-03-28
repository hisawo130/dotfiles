Run the nightly self-improvement batch manually (same as the 3 AM cron job).

Executes all 6 improvement tasks in order:
1. Memory consolidation — recurring promotion, dedup, old-entry trim, memory rule extraction
2. Autonomous operation review — CLAUDE.md 最小限見直し
3. Light refactoring — hooks/agents の明らかなバグのみ
4. Growth log — append daily report to `claude/scripts/growth-log.md`
5. Stale date patrol — expired deadlines → ✅ 期限済みに更新
6. Learning metrics — per-domain entry count table → growth log に追記

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
