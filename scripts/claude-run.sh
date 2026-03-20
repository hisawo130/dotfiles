#!/bin/bash
# claude-run — Claude Code ヘッドレス実行ラッパー
#
# 使い方:
#   claude-run "コードのバグを修正してコミットして"
#   claude-run --dir /path/to/project "テストを実行して修正して"
#   claude-run --tools Read,Grep,Write "依存関係を確認して"
#   claude-run --json "全テストを実行した結果を返して"
#
# SSH経由:
#   ssh user@host "~/dotfiles/scripts/claude-run.sh 'PRを作成して'"
#
# cron例（毎朝9時にdotfiles更新確認）:
#   0 9 * * * ~/dotfiles/scripts/claude-run.sh --dir ~/dotfiles "最新の変更を確認してサマリーを出力して"

set -euo pipefail

# --- デフォルト設定 ---
WORK_DIR="$(pwd)"
OUTPUT_FORMAT="text"
ALLOWED_TOOLS=""
MAX_TURNS=10
VERBOSE=false

# --- 引数パース ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir|-d)       WORK_DIR="$2";        shift 2 ;;
    --json|-j)      OUTPUT_FORMAT="json"; shift ;;
    --tools|-t)     ALLOWED_TOOLS="$2";   shift 2 ;;
    --turns|-n)     MAX_TURNS="$2";       shift 2 ;;
    --verbose|-v)   VERBOSE=true;         shift ;;
    --help|-h)
      sed -n '2,20p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      PROMPT="$*"
      break
      ;;
  esac
done

# --- 前提チェック ---
if [[ -z "${PROMPT:-}" ]]; then
  echo "エラー: プロンプトを指定してください" >&2
  echo "使い方: claude-run \"<プロンプト>\"" >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "エラー: claudeコマンドが見つかりません" >&2
  echo "インストール: npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  # ~/.secrets から読み込みを試みる
  [[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"
  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "エラー: ANTHROPIC_API_KEY が設定されていません" >&2
    exit 1
  fi
fi

# --- コマンド構築 ---
CMD=(claude -p "$PROMPT"
  --output-format "$OUTPUT_FORMAT"
  --max-turns "$MAX_TURNS"
  --dangerously-skip-permissions
)

[[ -n "$ALLOWED_TOOLS" ]] && CMD+=(--allowedTools "$ALLOWED_TOOLS")

# --- 実行 ---
if $VERBOSE; then
  echo "📁 作業ディレクトリ: $WORK_DIR" >&2
  echo "🤖 プロンプト: $PROMPT" >&2
  echo "⚙️  ツール: ${ALLOWED_TOOLS:-すべて}" >&2
  echo "---" >&2
fi

cd "$WORK_DIR"
exec "${CMD[@]}"
