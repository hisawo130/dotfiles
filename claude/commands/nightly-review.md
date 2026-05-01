Run the nightly self-improvement batch manually (same as the 3 AM cron job).

Executes 6 daily improvement tasks (+ 1 weekly task on Mondays) in order:
1. Memory consolidation — recurring promotion, dedup, old-entry trim, memory rule extraction
2. Autonomous operation review — CLAUDE.md 最小限見直し
3. Light refactoring — hooks/agents の明らかなバグのみ
4. Growth log — append daily report to `claude/scripts/growth-log.md`
5. Stale date patrol — expired deadlines → ✅ 期限済みに更新
6. Learning metrics — per-domain entry count table → growth log に追記
7. (週次 / 月曜のみ) Reference refresh — UPDATE BEFORE USE 対象を WebFetch で更新

Usage: /nightly-review

---

実行方法: 直接 bash を呼び出す。

```bash
DOTFILES=$(head -1 ~/.dotfiles-root 2>/dev/null || echo "$HOME/dotfiles")
bash "$DOTFILES/scripts/nightly-self-improve.sh"
```

完了後、`~/.claude/logs/nightly.log` で結果を確認できる。

cron への登録・削除・ステータス確認:
```bash
DOTFILES=$(head -1 ~/.dotfiles-root 2>/dev/null || echo "$HOME/dotfiles")
bash "$DOTFILES/scripts/install-nightly-cron.sh"           # AM3:00 に登録
bash "$DOTFILES/scripts/install-nightly-cron.sh" --status  # ログ確認
bash "$DOTFILES/scripts/install-nightly-cron.sh" --remove  # 削除
```
