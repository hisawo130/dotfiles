#!/bin/bash
# PreToolUse hook: block rm and redirect to ~/.trash/
# mv は allow リスト済みのため承認プロンプトが出ない

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

[ -z "$CMD" ] && exit 0

# クォート文字列を除去して誤検知を防ぐ (block-compound-commands.sh と同パターン)
STRIPPED=$(echo "$CMD" | sed \
  -e "s/'[^']*'//g" \
  -e 's/"[^"]*"//g' \
  -e 's/\$([^)]*)//g')

# ヒアドキュメント内は無視
if echo "$CMD" | grep -qF '<<'; then
  exit 0
fi

# rm を単独コマンドとして検知: 行頭 or ; && || | の後に rm + 空白orEOF
if echo "$STRIPPED" | grep -qE '(^|[;&|[:space:]])rm([[:space:]]|$)'; then
  # rmdir だけを含む場合はスキップ (空ディレクトリ削除は安全)
  if echo "$STRIPPED" | grep -qE '(^|[;&|[:space:]])rmdir([[:space:]]|$)' && \
     ! echo "$STRIPPED" | grep -qE '(^|[;&|[:space:]])rm([^d[:space:]]|[[:space:]]|$)'; then
    exit 0
  fi

  TRASH_EXAMPLE='mkdir -p ~/.trash && mv <ファイル> ~/.trash/$(date +%Y%m%d-%H%M%S)-<名前>'
  jq -n --arg cmd "$CMD" --arg ex "$TRASH_EXAMPLE" \
    '{"decision":"block","reason":("🗑️  `rm` は禁止されています。ファイルは完全削除せず ~/.trash/ へ移動してください。\n\n代替パターン:\n  " + $ex + "\n\nブロックされたコマンド: " + $cmd)}'
  exit 0
fi

exit 0
