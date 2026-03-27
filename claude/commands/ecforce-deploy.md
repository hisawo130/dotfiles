Deploy current changes to the ecforce theme and verify.

Steps:
1. Check for unsaved changes: `git status` — WIPがあれば先にコミットまたはstash
2. Run `git diff --staged` to confirm staged content is intentional
3. Confirm target is NOT `main`/`master` branch (staging deploys from feature branches)
4. Execute deploy command — check `Capfile` or `README` for exact command (`bundle exec cap staging deploy` etc.)
5. After deploy:
   - Report deploy status (success/failure)
   - Report staging URL
   - Note any migration output or errors
6. Remind to test the order flow (cart → checkout → thanks) for side effects

Note: ecforce is save=immediately-live on production. Always duplicate theme before editing in production.
