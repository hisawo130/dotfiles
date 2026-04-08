#!/bin/bash
# install-nightly-cron.sh
# 夜間自己改善バッチを cron に登録する。
#
# 使い方:
#   bash ~/dotfiles/scripts/install-nightly-cron.sh          # AM3:00 JST に登録
#   bash ~/dotfiles/scripts/install-nightly-cron.sh --remove # 削除
#   bash ~/dotfiles/scripts/install-nightly-cron.sh --status # 確認

set -euo pipefail

SCRIPT="$HOME/dotfiles/scripts/nightly-self-improve.sh"
LOG="$HOME/.claude/logs/nightly.log"
CRON_MARK="# claude-nightly-self-improve"

# JST は UTC+9。cron はシステム時刻を使うため、
# システムが UTC なら "0 18 * * *"、JST なら "0 3 * * *"
detect_tz_offset() {
  offset=$(date +%z 2>/dev/null || echo "+0000")
  echo "$offset"
}

get_cron_time() {
  local offset
  offset=$(detect_tz_offset)
  if [[ "$offset" == "+0900" ]] || [[ "$offset" == "JST" ]]; then
    echo "0 3 * * 1-5"   # システムが JST: 月〜金 AM3:00
  else
    echo "0 18 * * 1-5"  # システムが UTC: 18:00 UTC = 03:00 JST、月〜金のみ
  fi
}

CRON_TIME=$(get_cron_time)
CRON_LINE="${CRON_TIME} bash ${SCRIPT} ${CRON_MARK}"

case "${1:---install}" in
  --remove)
    current=$(crontab -l 2>/dev/null || true)
    updated=$(echo "$current" | grep -v "$CRON_MARK")
    echo "$updated" | crontab -
    echo "✅ 夜間バッチ cron を削除しました"
    ;;
  --status)
    echo "=== 現在の cron (nightly-self-improve) ==="
    crontab -l 2>/dev/null | grep "$CRON_MARK" || echo "(登録なし)"
    echo ""
    echo "=== 最新ログ (tail -20) ==="
    mkdir -p "$(dirname "$LOG")"
    tail -20 "$LOG" 2>/dev/null || echo "(ログなし)"
    ;;
  --install|*)
    chmod +x "$SCRIPT"
    mkdir -p "$(dirname "$LOG")"

    # 既存エントリを削除してから追加（冪等性）
    current=$(crontab -l 2>/dev/null | grep -v "$CRON_MARK" || true)
    (echo "$current"; echo "$CRON_LINE") | crontab -

    echo "✅ 夜間自己改善バッチを cron に登録しました"
    echo "   スケジュール: $CRON_TIME (TZ offset: $(detect_tz_offset))"
    echo "   スクリプト : $SCRIPT"
    echo "   ログ       : $LOG"
    echo ""
    echo "確認コマンド: bash $HOME/dotfiles/scripts/install-nightly-cron.sh --status"
    ;;
esac
