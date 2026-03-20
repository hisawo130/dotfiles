# /headless — ヘッドレス・リモート実行パターン集

Claude Code を非インタラクティブ（ヘッドレス）モードで実行するパターン集。
CI/CD・cron・SSH リモートで活用する。

---

## 基本構文

```bash
claude -p "<プロンプト>" --dangerously-skip-permissions
```

| フラグ | 説明 |
|---|---|
| `-p "<prompt>"` | ヘッドレス実行 (print mode) — 1ターンで終了 |
| `--dangerously-skip-permissions` | 確認プロンプトをすべてスキップ (CI必須) |
| `--output-format json` | JSON で出力 (パース用) |
| `--output-format stream-json` | ストリーミング JSON |
| `--output-format text` | プレーンテキスト (デフォルト) |
| `--max-turns N` | 最大ターン数制限 |
| `--allowedTools "Read,Grep"` | 使用可能ツールを限定 |

---

## よく使うパターン

### 1. テーマチェック & 結果をファイルに保存
```bash
claude-run --dir ~/shopify-theme \
  "Run theme check on the current theme and output a summary of errors only." \
  --json > /tmp/theme-check-result.json
```

### 2. diff を見て PR 説明文を生成
```bash
DIFF=$(git diff main..HEAD --stat)
claude -p "以下の git diff を見て、日本語で PR 説明文（背景・変更概要・テスト済み項目）を生成:\n$DIFF" \
  --dangerously-skip-permissions
```

### 3. Liquid ファイルのレビュー
```bash
cat templates/product.liquid | \
  claude -p "Review this Liquid template for performance issues and Shopify best practices." \
    --dangerously-skip-permissions
```

### 4. SSH リモート実行
```bash
# サーバーに SSH してコードが存在する場所で実行
ssh myserver "cd /srv/shopify-theme && \
  claude -p 'Check for deprecated Liquid filters and list files that need updating.' \
    --dangerously-skip-permissions --output-format json"
```

### 5. cron で毎日テーマ監査
```bash
# crontab -e
0 9 * * 1 cd ~/shopify-theme && \
  claude -p "週次テーマ監査: 未使用ファイル・廃止APIの使用・パフォーマンス懸念を報告" \
    --dangerously-skip-permissions >> ~/logs/theme-audit.log 2>&1
```

---

## `claude-run` ラッパースクリプト

`setup.sh` でインストール済み: `~/.local/bin/claude-run`

```bash
# 基本
claude-run "テーマのスニペット一覧を出力して"

# 作業ディレクトリ指定
claude-run --dir ~/projects/my-theme "未使用の CSS クラスを探して"

# JSON 出力
claude-run --json "package.json の依存を確認してセキュリティ問題を報告"

# ツール制限 (読み取り専用)
claude-run --tools "Read,Grep,Glob" "全 Liquid テンプレートをスキャンして metafield の使用状況を集計"

# ターン数制限
claude-run --turns 5 "Shopify Section のスキーマを全部列挙して"
```

---

## GitHub Actions での使用

`claude/templates/claude.yml` を `.github/workflows/` にコピーして使用。

```yaml
- name: Run Claude audit
  run: |
    claude -p "本番デプロイ前の最終チェックを実行" \
      --dangerously-skip-permissions \
      --output-format json
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

---

## CI 用設定 (`settings.ci.json`)

`~/.claude/settings.json` の代わりに使用する最小権限プロファイル:

```bash
CLAUDE_CONFIG_DIR=/path/to/ci-config claude -p "..." --dangerously-skip-permissions
```

`claude/templates/settings.ci.json` を参照。

---

## 注意事項

- `--dangerously-skip-permissions` は **CI・自動化専用** — インタラクティブ作業では使わない
- ANTHROPIC_API_KEY が必要: `~/.secrets` または環境変数で設定
- 非インタラクティブ時は確認を求めず、自動で判断して進める
- 長いタスクは `--max-turns` で暴走を防ぐ (推奨: 10–20)
