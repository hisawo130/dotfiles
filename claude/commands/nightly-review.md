Run the nightly self-improvement batch manually (same as the 3 AM cron job).

Executes tasks in order:

**Python pipeline (AI-free, always runs):**
1. Stale date patrol — expired deadlines → ✅ 期限済みに更新 (preprocess.py)
2. Learning metrics — per-domain entry count table → growth log scaffold (preprocess.py)
3. Shell validate — bash -n + shellcheck for all hooks/scripts (validate-shell.py)
4. Growth log — fill placeholders from preprocess + shell results (postprocess.py)

**AI review (claude -p, headless):**
5. Memory consolidation — recurring promotion, dedup, old-entry trim, memory rule extraction
6. CLAUDE.md review — repeated mistakes → CLAUDE.md rules
7. Light refactoring — hooks/agents の明らかなバグのみ
8. Growth log observations — pattern analysis
9. (週次 / 月曜のみ) Reference refresh — UPDATE BEFORE USE 対象を WebFetch で更新

**NotebookLM sync (requires nlm auth):**
10. Master Brain push — today's growth-log entry → Master Brain notebook

Usage: /nightly-review

---

実行方法: 直接 bash を呼び出す。

```bash
DOTFILES=$(head -1 ~/.dotfiles-root 2>/dev/null || echo "$HOME/dotfiles")
bash "$DOTFILES/scripts/nightly-self-improve.sh"
```

完了後、`~/.claude/logs/nightly.log` で結果を確認できる。

Master Brain へのクエリ（任意）:
```bash
nlm notebook query 58f81c6c-6f3e-42d1-9de5-e59b8975f51c "質問"
```

cron への登録・削除・ステータス確認:
```bash
DOTFILES=$(head -1 ~/.dotfiles-root 2>/dev/null || echo "$HOME/dotfiles")
bash "$DOTFILES/scripts/install-nightly-cron.sh"           # AM3:00 に登録
bash "$DOTFILES/scripts/install-nightly-cron.sh" --status  # ログ確認
bash "$DOTFILES/scripts/install-nightly-cron.sh" --remove  # 削除
```
