#!/bin/bash
# UserPromptSubmit: プロンプト複雑度を判定してエフォートヒントを注入
# lite  → 🟢 直接回答、サブエージェント不要
# heavy → 🔴 Explore=haiku、実装=sonnet直接
# medium → 出力なし（デフォルト動作）

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
[ -z "$PROMPT" ] && exit 0

CHAR_COUNT=${#PROMPT}

# lite: 短い or 質問・確認系
if [ "$CHAR_COUNT" -lt 25 ] || \
   echo "$PROMPT" | grep -qiE '(読んで|確認|教えて|どこ|何|なぜ|どう|[？?]$|見て$|調べて$|一覧|リスト|状態|status)'; then
  jq -n '{"systemMessage": "🟢 [lite] 直接・簡潔に回答。サブエージェントは不要。"}'
  exit 0
fi

# heavy: 実装・設計・リファクタリング系
if echo "$PROMPT" | grep -qiE '(実装|作って|作る|設計|リファクタリング|全部|全体|自動化|スクリプト|フック|仕様|計画|refactor|migrate|architect)'; then
  jq -n '{"systemMessage": "🔴 [heavy] Explore/検索はhaiku。実装はsonnet直接。複数ファイルならプランから。"}'
  exit 0
fi

exit 0
