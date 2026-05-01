#!/bin/bash
# nightly-self-improve.sh
# 毎日 AM3:00 に実行する自動自己改善バッチ。
#
# 実行内容:
#   STEP 1 — 学習ログの整理 (pure bash: recurring昇格・重複除去・古いfallback削除)
#   STEP 2 — AI自己レビュー (claude -p: 記憶整理 / CLAUDE.md見直し / 成長ログ生成)
#   STEP 3 — dotfiles に全変更をコミット
#
# cron 登録例 (JST AM3:00):
#   0 3 * * * $HOME/dotfiles/scripts/nightly-self-improve.sh >> $HOME/.claude/logs/nightly.log 2>&1

set -euo pipefail

# Resolve dotfiles root (handles non-default install paths)
if [ -f "$HOME/.dotfiles-root" ]; then
  DOTFILES=$(head -1 "$HOME/.dotfiles-root" 2>/dev/null || echo "")
fi
[ -z "${DOTFILES:-}" ] || [ ! -d "$DOTFILES/claude" ] && DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

LEARNINGS_DIR="$HOME/.claude/learnings"
MEMORY_DIR="$HOME/.claude/memory"
LOG_DIR="$HOME/.claude/logs"
PROMPTS_DIR="$DOTFILES/claude/scripts/prompts"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/nightly.log" 2>&1

echo ""
echo "═══════════════════════════════════════════"
echo "🌙 nightly-self-improve — $DATE $TIME JST"
echo "═══════════════════════════════════════════"

# ── ガード: 二重起動防止 ──────────────────────────────────────────────────────
LOCK_FILE="$HOME/.claude/logs/.nightly-batch.lock"
if [ -f "$LOCK_FILE" ]; then
  # SIGKILL でトラップが迂回された場合のスタックロック回収 (2時間以上 = 強制終了と判定)
  _lock_mtime=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
  _lock_age=$(( $(date +%s) - _lock_mtime ))
  if [ "$_lock_age" -lt 7200 ]; then
    echo "[SKIP] 既に実行中またはロックファイルが存在します: $LOCK_FILE"
    exit 0
  else
    echo "[WARN] スタックロックを検出 (${_lock_age}秒経過)。削除して続行します"
    rm -f "$LOCK_FILE"
  fi
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ── STEP 1: 学習ログの整理 (pure bash) ──────────────────────────────────────
echo ""
echo "── STEP 1: 学習ログの整理 ──"

step1_changed=0

for file in "$LEARNINGS_DIR"/*.md; do
  [ -f "$file" ] || continue
  domain=$(basename "$file" .md)
  original_lines=$(wc -l < "$file")

  # 1a: [gotcha] が 3 回以上出現するキーを [recurring] に昇格
  RECURRING_HDR="## Recurring Patterns"
  date_now=$(date +%Y-%m-%d)

  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    key="${entry:0:50}"
    count=$(grep -cF "$key" "$file" 2>/dev/null || echo 0)
    if [ "$count" -ge 3 ]; then
      if grep '\[recurring\]' "$file" 2>/dev/null | grep -qF "$key"; then
        continue  # すでに登録済み
      fi
      if grep -q "$RECURRING_HDR" "$file"; then
        _tmp=$(mktemp)
        sed "/$RECURRING_HDR/a - [recurring] ${key} — seen ${count} times" "$file" > "$_tmp" && mv "$_tmp" "$file"
      else
        printf '\n%s (updated %s)\n- [recurring] %s — seen %s times\n' \
          "$RECURRING_HDR" "$date_now" "$key" "$count" >> "$file"
      fi
      echo "  [recurring昇格] $domain: $key"
      step1_changed=1
    fi
  done < <(grep '\[gotcha\]' "$file" 2>/dev/null | sed 's/^- //' | sed 's/\[gotcha\] //')

  # 1b: 90日以上前の plain fallback エントリを削除
  #      (タグなしの "- 作業:" や "- 完了:" 行)
  cutoff=$(date -d "90 days ago" +%Y-%m-%d 2>/dev/null || date -v-90d +%Y-%m-%d 2>/dev/null || echo "")
  if [ -n "$cutoff" ]; then
    # ヘッダー「## YYYY-MM-DD」の日付が cutoff より古く、
    # そのブロック内に [gotcha/pattern/tip/correction/recurring/open] がなければ削除
    python3 - "$file" "$cutoff" <<'PYEOF' 2>/dev/null && step1_changed=1 || true
import sys, re, os

filepath = sys.argv[1]
cutoff   = sys.argv[2]

with open(filepath, encoding='utf-8') as f:
    content = f.read()

# セクションを分割 (## で始まる行がヘッダー)
sections = re.split(r'(?=^## )', content, flags=re.MULTILINE)
kept = []
removed = 0

for sec in sections:
    # "## Recurring Patterns" セクションは常に保持
    if sec.startswith('## Recurring'):
        kept.append(sec)
        continue
    # タイトルセクション (# で始まる) は保持
    if sec.startswith('# ') or not sec.startswith('## '):
        kept.append(sec)
        continue
    # 日付ヘッダーを探す
    date_match = re.match(r'^## (\d{4}-\d{2}-\d{2})', sec)
    if not date_match:
        kept.append(sec)
        continue
    sec_date = date_match.group(1)
    # 古い + タグなし (plain fallback のみ) なら削除
    has_tag = re.search(r'\[(gotcha|pattern|tip|correction|recurring|open)\]', sec)
    if sec_date < cutoff and not has_tag:
        removed += 1
    else:
        kept.append(sec)

if removed > 0:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(''.join(kept))
    print(f"  [古いfallback削除] {os.path.basename(filepath)}: {removed}件")
PYEOF

  fi

  # 1c: 完全重複行の除去
  tmp=$(mktemp)
  awk '!seen[$0]++' "$file" > "$tmp"
  new_lines=$(wc -l < "$tmp")
  if [ "$original_lines" -ne "$new_lines" ]; then
    mv "$tmp" "$file"
    echo "  [重複除去] $domain: $((original_lines - new_lines)) 行削除"
    step1_changed=1
  else
    rm -f "$tmp"
  fi
done

[ "$step1_changed" -eq 0 ] && echo "  (変更なし)" || echo "  完了"

# ── STEP 2: スクリプト自己改善 (AI 不要) ────────────────────────────────────
echo ""
echo "── STEP 2: スクリプト自己改善 ──"

PREPROCESS="$DOTFILES/scripts/nightly-preprocess.py"
VALIDATE_SH="$DOTFILES/scripts/nightly-validate-shell.py"
POSTPROCESS="$DOTFILES/scripts/nightly-postprocess.py"
DIGEST_FILE="$LOG_DIR/nightly-digest.json"
SHELL_RESULT="$LOG_DIR/nightly-shell.json"

python3 "$PREPROCESS" > "$DIGEST_FILE" 2>&1 \
  && echo "  前処理完了 (stale dates + metrics + gotcha候補 + growth-log scaffold)" \
  || echo "  [WARNING] 前処理エラー"

python3 "$VALIDATE_SH" > "$SHELL_RESULT" 2>&1 \
  && echo "  シェル構文チェック完了" \
  || echo "  [WARNING] シェルチェックエラー"

python3 "$POSTPROCESS" "$DIGEST_FILE" "$SHELL_RESULT" 2>&1 \
  && echo "  成長ログ記入完了" \
  || echo "  [WARNING] 後処理エラー"

# ── STEP 2.5: settings.local.json 掃除（月曜のみ・週1）──────────────────────
if [ "$(date +%u)" = "1" ]; then
  echo ""
  echo "── STEP 2.5: settings.local.json 掃除 (週次) ──"
  python3 "$DOTFILES/claude/tools/cleanup-local-permissions.py" --apply 2>&1 \
    | sed 's/^/  /' || echo "  [WARNING] 掃除エラー"
fi

# ── STEP 3: dotfiles に全変更をコミット ──────────────────────────────────────
echo ""
echo "── STEP 3: dotfiles コミット ──"

if git -C "$DOTFILES" rev-parse --is-inside-work-tree &>/dev/null; then
  # 学習ログ・メモリ・成長ログの変更をステージ
  git -C "$DOTFILES" add \
    "claude/learnings/" \
    "claude/memory/" \
    "claude/CLAUDE.md" \
    "claude/scripts/growth-log.md" 2>/dev/null || true

  if ! git -C "$DOTFILES" diff --cached --quiet 2>/dev/null; then
    git -C "$DOTFILES" commit \
      -m "chore: 🌙 nightly self-improve ($DATE)" 2>/dev/null
    echo "  コミット完了"

    # push は session-end-notify.sh 相当の処理
    unpushed=$(git -C "$DOTFILES" log --oneline @{u}..HEAD 2>/dev/null || true)
    if [ -n "$unpushed" ]; then
      git -C "$DOTFILES" push 2>/dev/null && echo "  プッシュ完了" || echo "  [WARNING] プッシュ失敗"
    fi
  else
    echo "  (コミットすべき変更なし)"
  fi
fi

echo ""
echo "✅ nightly-self-improve 完了 — $DATE $TIME"
