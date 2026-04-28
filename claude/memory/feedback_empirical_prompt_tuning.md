---
name: empirical-prompt-tuning methodology
description: スキル・プロンプト改善の手法。作者バイアスを排除するためバイアスフリーサブエージェントで実行評価し、1テーマずつ修正して収束まで繰り返す
type: feedback
originSessionId: 142517fc-eb61-4b55-9926-de135e789885
---
スキルやプロンプトを改善するときは **empirical-prompt-tuning** の手法を使う。

**Why:** プロンプトの作者は自分の文章を客観的に読めない。「明確だ」と思うほど別エージェントが詰まる。

**How to apply:**

1. **静的チェック（iter 0）**: frontmatterの`description`と本文のスコープが一致しているか確認。ズレがあると評価が false positive になる
2. **バイアスフリーサブエージェントで実行**: Agent toolで新規エージェントを起動。自己再読は NG（バイアスが入るため信頼できない）
3. **Two-sided evaluation**:
   - executor自己レポート: 不明点・裁量補完・詰まり箇所
   - 命令側メトリクス: 成功/失敗、達成率%、`tool_uses`（相対比較）、duration_ms、retry数
4. **Phase tagging**: Understanding / Planning / Execution / Formatting でどこが詰まったか特定
5. **1イテレーション1テーマ**: 複数修正を同時に入れると「何が効いたか」不明になる
6. **Failure pattern ledger**: 修正前にledgerを確認。同じパターンが3回+ 出たら構造的欠陥（パッチではなく書き直し）
7. **収束判定**: 2連続イテレーションで「新規不明点ゼロ ＋ 精度改善+3pt以下」→ hold-outシナリオで過学習チェック

**`tool_uses`の解釈**:
- シナリオ間で3-5倍以上の差 → そのスキルが自己完結していない（executor が参照を漁っている）
- 精度100%でも`tool_uses`の偏りがあれば iter 2 を走らせる理由になる

**収束後**: `superpowers:writing-skills` → empirical tuning → `capture` でledgerをメモリに保存

参照元: https://github.com/mizchi/skills/blob/main/empirical-prompt-tuning/SKILL.md
