# General Learnings

## 2026-04-24 22:36 | dotfiles [ai]
- [gotcha] セッション起動時の自動pullは未コミット変更があるとコンフリクト。`--ff-only`を併用し、失敗時は警告して停止する。
- [pattern] セッション開始フック実装前に、既存フック（pull-dotfiles.sh等）との重複を確認し、統一・整理が必須。
- [pattern] 複数PC運用では起動時に `git pull --ff-only` を自動実行。SessionStart フックで古い状態での作業開始を防ぐ。
- [pattern] 大量ファイル処理のバッチ処理は、クライアント前処理（Python要約生成）→Claude軽量処理（JSON digest受け取り）→後処理スクリプト（ファイル書込）の3段階に分割するとトークン削減と再現性が両立
- [gotcha] 定期実行バッチ（cron）では「データ集計・パトロール・パターンマッチ」などPythonで完結できる処理をClaudeに通さない設計が必須。生ファイル一括読み込みはスケールしない
- [tip] JSON digest形式での前後処理分離は、Claude側プロンプトも簡潔に保ち「判断・観察」のみに専念させるため、定期実行タスクには特に有効
- [pattern] Claude→Python切り分け：期限パトロール・集計など定型処理はPythonで完結させ、ClaudeはJSON digestのみ→トークン大幅削減
- [pattern] Preprocess→Claude→Postprocess：生ファイルIOはスクリプト側に専任し、Claudeは要約JSON入出力のみ→max-turns削減も実現
- [gotcha] プロンプト最適化だけではトークン削減の限界あり、Claudeの作業範囲をアーキテクチャレベルで縮小する方が効果的
- [pattern] バッチ処理のトークン消費が大きい場合、前処理（ファイル読み込み）→ Claudeダイジェスト処理 → 後処理（ファイル書き込み）に分離。Claude は JSON摘要のみ扱い、生ファイル I/O をスクリプトに完全に委譲。max-turns も 30→5 に短縮可能。
- [gotcha] cronジョブのスケジューリング時、「要件策定時点で」ユーザー使用時間帯・ルール期限（5h/7d）との重複確認を済ませ、設定後の事後確認に頼らない。
- [tip] バッチ処理設計で「判定ロジックが純粋（正規表現・集計等）な処理」と「理由説明が必要な処理」を明確に分離。前者は Python で完結、後者のみ Claude に渡す。
- [pattern] 大量ファイル読み込みはPython前処理で要約化し、ClaudeはJSON I/Oのみに限定。トークン消費を90%削減できる。
- [pattern] レートリミットリセット時刻（5h=AM8:00、7d=月曜）を意識し、自動処理をリセット後に実行。週末を除外(cron `1-5`)することで月曜開始時の消費を0に近づける。
- [tip] 複数ファイルの batch 処理は Python スクリプト 1本 + preprocess/postprocess で責務を分離。Claudeは JSON ダイジェストの高度な判断のみ担当。
- [pattern] 大規模なメンテナンスタスク（複数ファイル読み書き）はPythonで前処理・後処理に分離、Claudeは要約入力→JSON出力のみにするとトークン消費が大幅削減される
- [pattern] cron スケジュール設計時は5h/7dレートリミットリセット時刻と利用時間帯の重なりを避け、平日のみ実行（`0 3 * * 1-5`）にするとリセット時点で使用量0%になる
- [gotcha] cron設定を変更してもシステムに反映されるまで手動確認が必要（`crontab -l`で登録状況確認してから初回実行テスト）
- [pattern] トークン削減: Claude→生ファイル読み込みの代わりに、Python前処理で要約JSON生成 → Claude→JSON入出力のみ → Python後処理で書き込み。Read/Edit/Writeコール削減。
- [pattern] 定期実行タスクのスケジュール最適化: レートリミットリセット時刻（5h/7d）を考慮し、weekday-only cronで実行（月〜金AM3:00）。前日の消費を翌営業日開始時点で最小化。
- [gotcha] cronの一元化: 複数PCでローカル登録は管理コスト高。GitHub Actionsで一元化すれば、PCのオン/オフに左右されず確実に実行可能だが、APIキー・CI設定が必要。
- [pattern] Claudeのトークン消費削減には、生ファイル読み込み（複数Read/Edit）をPythonスクリプト前処理に移行。JSONダイジェストのみ渡し、JSON出力受け取りで完結させる
- [gotcha] 「ユーザー使用時間帯を避ける」と「レートリミット消費タイミング」は別概念。スケジュール時刻は使用時間帯以外ならOK。レートリミットはAPI仕様であり、スケジュール対象ではない
- [tip] 複数PCのcron一元化はローカル登録ではなくGitHub Actionsで。PCの稼働状態に依存せず確実に実行できる
- [pattern] トークン消費を減らすなら、Claude はダイジェスト（JSON要約）のみ受け取り、ファイル読み込み・書き込みは前処理・後処理のPythonスクリプトに全て委譲するアーキテクチャにする。Read/Edit/Writeコールがほぼ0になり、プロンプト自体も短縮可能
- [gotcha] 複数PC環境でのcron管理：各PCで手動登録が必要で同期されない。一元化したいなら GitHub Actions の schedule トリガーで実行し、API キーを Secrets に登録することで、PC依存を排除できる
- [pattern] 大量のファイル読み書きが必要な場合、Claude→Python→Claudeの3層アーキテクチャを使用。前処理（preprocess.py）が生ファイルをJSON要約に圧縮し、Claudeが生ファイルを読まないようにすることでトークン消費を劇的に削減。
- [tip] cronスケジュール `0 3 * * 1-5` で曜日指定（月〜金のみ実行）にすると、Rate limit 7d windowをリセット前に避けられる。毎日実行だと土日の消費が無駄になるため、使用時間帯（AM9-PM21）の前にリセットを完成させるなら曜日制限が効果的。
- [gotcha] GitHub ActionsでAnthropicを使う場合、リポジトリSecretsに `ANTHROPIC_API_KEY` を登録しないと実行時に失敗する。ローカルのシェル変数との区別が必要。
- [pattern] Claudeとスクリプトの分業：ファイル読み込み・整形はPython preprocess/postprocessで纏め、ClaudeはコンパクトなJSON digestのみ処理 → トークン削減、max-turns短縮
- [gotcha] 複数PC環境ではローカルcronは管理コストが高い。GitHub Actionsで一元化して各PCの状態に依存させない
- [tip] レートリミット対策：5h/7dリセット後に処理が完了するよう、AM3:00実行+平日のみスケジュール → 使用開始時に消費量0%を確保
- [pattern] トークン削減：ファイル読み込み→集計→書き込みをPythonで完結し、ClaudeはJSON要約を受け取るだけ。生ファイルはRead/Edit/Writeコールゼロに削減
- [gotcha] GitHubActions YAMLで複数行文字列（ヒアドキュメント）を埋め込むとパーサー衝突。プロンプト生成は別Pythonスクリプトに切り出す
- [pattern] レートリミット管理：nightly taskを月〜金のみ実行(cron: `0 3 * * 1-5`)すると、土日ノータッチで月曜AM9:00時点の7d消費が最小化される
- [pattern] Claudeプロンプトでファイル読み込みの最小化 — 生ファイルを直接読まず、Pythonで事前集計・JSON要約を生成してから渡す。トークン消費が大幅削減される。
- [gotcha] YAMLヒアドキュメント（`<<'PYEOF'`）はGitHub Actionsパーサーと衝突 — ワークフロー内でのPython埋め込みは別ファイル切り出しが必須。
- [pattern] cron スケジュール `0 3 * * 1-5`（月〜金AM3:00のみ）で5h/7dレート制限を最適化 — AM8:00/月曜AM9:00開始時に消費を最小化できる。
- [pattern] Claudeが繰り返しファイル読み書きする大規模自動化は、preprocess（JSON化）→ Claude（JSON処理）→postprocess（一括書き込み）に分割するとトークン大幅削減できる
- [gotcha] GitHub ActionsのYAML内で`<<'PYEOF'`などヒアドキュメントを使うとパーサーエラーになる；プロンプト生成は別スクリプトに切り出す
- [tip] cronスケジュール`0 3 * * 1-5`（月～金のみ）で、5h・7dレートリミットリセット時点の消費を最適化；複数PCはGitHub Actions一元化で対応
- [pattern] Claudeの大規模ファイル処理はPreprocess/Postprocess分離で効率化 — 生ファイル読込を避け、JSONダイジェスト→JSON応答の1ラウンドに集約でトークン消費を30→5ターンに削減
- [gotcha] シェルスクリプト内で`sed`を使ったマルチラインJSON置換はYAML/パーサーエラーを招く → Pythonスクリプトに切り出して生成するべき
- [tip] GitHub Actions cron日本時間指定は`schedule: '0 18 * * 1-5'`（UTC）で平日AM3:00 JST実行可 — ローカルcronより一元化・信頼性が高い
- [pattern] プリプロセス/ポストプロセス分離でトークン削減 — Claudeが生ファイルを読まない仕組みに変更し、preprocess.pyでJSON要約化→Claude JSON処理→postprocess.pyで一括書き込み、max-turnsも30→5に削減
- [gotcha] ワークフロー内のヒアドキュメント+sedはYAML衝突 — `<<'PYEOF'` などの複多行テキストはYAMLパーサーの解釈エラーの原因、スクリプトは別ファイルに切り出すべき
- [tip] レートリミット（5h/7d）を考慮したcronスケジュール — 5hはAM3:00実行→AM8:00リセット→AM9:00開始時0%、7dは土日除外（月〜金のみ）で月曜開始時に最小化
- [pattern] JSONダイジェスト方式でClaudeのトークン消費を削減。生ファイル読み込みの代わりにpreprocess.pyで要約化したJSON（メモリ件数、メトリクス集計など）をClaudeに渡す方式で、Read/Edit/Writeツールコール数を大幅削減できる
- [gotcha] シェル内のヒアドキュメント（`<<'PYEOF'`）はYAMLパーサーと衝突する。ワークフロー内でプロンプト生成する場合は、テキスト置換ではなくPythonスクリプトを別ファイルに切り出すべき
- [tip] cronスケジュールを平日指定（`0 3 * * 1-5`）にすると、7dレートリミットリセットのタイミングで週末の消費を避けられ、月曜開始時に0%から開始できる
- [pattern] Claude処理のトークン削減：生ファイル読み込みを前処理Pythonに移行（JSON要約化），Claude出力をJSON短形式に限定，後処理Pythonで一括書き込み。max-turns大幅削減でき，APIコスト最適化に有効。
- [pattern] APIレートリミット最適化：リセット時刻（5h: +08:00 JST, 7d: 月曜）を逆算し，スケジュール（月〜金AM3:00 JST）を設計することで，毎日の使用開始時を0%から開始可能。
- [gotcha] GitHub ActionsのYAMLでJSON生成：ヒアドキュメント（`<<'EOF'`）がYAMLパーサーと衝突。複雑な文字列生成はPython別ファイルに切り出し，YAMLからはそのスクリプト呼び出しに統一すべき。
- [pattern] Claude実行のトークン削減：生ファイルをClaudeに読ませず、前処理スクリプトで要約JSONを生成し、ClaudeはJSON入力/出力のみに限定。Task 5/6などは純粋Python処理で完結。max-turns 30→5、toolコール0化を実現
- [gotcha] cronスケジュール式で平日のみ指定時は `*` でなく `1-5` と明記。`0 3 * * *`（毎日）と `0 3 * * 1-5`（月〜金）は見た目似ているが挙動が異なる。
- [gotcha] GitHub ActionsのYAML内で複数行ヒアドキュメント（`<<'EOF'`）を直接埋め込むとYAMLパーサーがエラー。プロンプト生成は別スクリプト `.py` に切り出すべき。
- [pattern] トークン削減の本質は「Claude がファイルを読まない」こと。プリプロセス（JSON digest生成）→ Claude が JSON 出力 → ポストプロセス（一括書き込み）で Read/Edit/Write コール 0 化。
- [pattern] YAML ヒアドキュメント（`<<'PYEOF'`）内で複数行 JSON 生成は YAML パーサーと衝突。プロンプト生成を別ファイル化、または Python 内で直接構築する方が安定。
- [tip] 複数 PC の cron 管理は GitHub Actions に一元化が吉。ローカル登録の手間削減＆PC 依存排除。API キーを Secrets 登録するだけで確実に実行。
- [pattern] 大量の小ファイル読み書きが必要な場合、preprocess.py で全データを JSON に集約 → Claude は JSON ダイジェストのみ処理 → postprocess.py が結果を一括書き込み。Read/Edit/Write ツールコールをほぼゼロに削減し max-turns を 30→5 に短縮。
- [gotcha] YAML workflow ファイルに `<<'PYEOF'` ヒアドキュメントを直接埋め込むと構文衝突。複雑なスクリプト生成は別 Python ファイルに切り出して呼び出すこと。
- [pattern] 複数 PC での自動実行は GitHub Actions で一元化（ローカル cron は不要）。ワークフロー `schedule` + `workflow_dispatch` で、単一の真実のソース + 手動実行も実現。
- [pattern] Claude側はJSONダイジェストのみ受け取り、ファイル読み込み・書き込みをpre/postprocess Pythonスクリプトに委ねることで、Read/Edit/Writeコール0に削減。トークン大幅削減。
- [gotcha] YAML ワークフロー内で複数行ヒアドキュメント（`<<'PYEOF'`）を直接埋め込むとパーサーエラー。プロンプト生成スクリプトは別ファイルに切り出すべき。
- [pattern] 複数 PC のローカルcronより GitHub Actions で一元化すると、PC稼働状態に依存せず確実に実行可能。スケジュール制御（土日除外など）も一箇所で管理できる。
- [pattern] 大量ファイル読み込みでClaudeトークン消費が課題な場合、前処理スクリプト→JSONダイジェスト→Claude→後処理スクリプト の3層構造でClaudeへの生ファイル読み込みを排除すると効果的。
- [gotcha] YAML ワークフロー内で複数行ヒアドキュメント（`<<'EOF'`）を展開するとパーサー衝突する。環境変数代入または別ファイル切り出しで回避。
- [tip] 複数PC のcron管理を統一する場合、GitHub Actions の`schedule`トリガーで一元化し、スケジュール式（`0 3 * * 1-5`）で曜日制限すると保守が簡単。
- [gotcha] YAMLでヒアドキュメント内にPython/shellスクリプトを埋め込むとYAMLパーサーと衝突してエラー。複数行スクリプトは別ファイル化して参照させる。
- [pattern] 大規模Claude処理はpreprocess（Python集計）→ Claude（JSON digest受け取り）→ postprocess（ファイル書き込み）で分割。生ファイルのRead/Edit削減でトークン大幅節約。
- [gotcha] GitHub ActionsのCI環境ではローカル環境変数は未設定。Anthropic APIキーは必ずリポジトリSecretsに登録して `${{ secrets.ANTHROPIC_API_KEY }}` で参照する。
- [pattern] Claude定期処理をトークン効率化する場合、前処理スクリプト（要約生成）と後処理スクリプト（ファイル書き込み）に分離し、Claude呼び出しをJSON入出力に絞る
- [gotcha] GitHub ActionsでClaude APIを使う場合、Secretsに`ANTHROPIC_API_KEY`が登録されていないとクレジット確認ステップで失敗
- [pattern] 複数PCで同じ定期タスク実行が必要な場合、ローカルcronよりGitHub Actionsで一元化する（PC状態に依存しない自動実行）
- [pattern] Claude APIトークン削減：生ファイル読み込みをPython前処理に移し、ClaudeはコンパクトなJSONダイジェストのみ受け取り、JSON出力で返すアーキテクチャにより、トークン消費をほぼゼロに削減できた。大量ファイル処理タスクに応用可能。
- [gotcha] YAMLヒアドキュメント衝突：ワークフローファイル内で`<<'PYEOF'`などヒアドキュメントを直接記述するとYAMLパーサーが混乱する。複雑なスクリプト生成はPythonスクリプトファイルに切り出して呼び出すべき。
- [tip] APIレート制限最適化：クレジットリセット時刻(AM8:00)より前にタスク実行(AM3:00)すれば利用開始時(AM9:00)でリセット完了。土日除外で累積消費最小化。
- [pattern] 大量ファイル処理・トークン最適化：生ファイルをClaudeに読ませず、前処理スクリプトで要約JSONを生成 → Claude（JSON digest受取）→ 後処理スクリプトで一括書き込み。max-turnsも削減。
- [gotcha] シェルスクリプトでClaudeプロンプト生成時、ヒアドキュメント + YAMLが衝突。GitHub Actionsではプロンプトテンプレートを外部Pythonスクリプトに切り出すべき。
- [tip] レートリミット最適化：nightly taskを土日除外（月〜金のみ）+ 実行時刻をリセット後に設定。5h/7dウィンドウ開始時に消費を0%状態に保持。
- [pattern] 大規模プロンプトのトークン最適化 — 前処理スクリプト(preprocess.py)でファイル読み込み・要約、ClaudeはJSONダイジェストのみ受け取る方式でmax-turnsを30→5に削減
- [gotcha] GitHub ActionsのYAMLで`<<'PYEOF'`ヒアドキュメント使用時、YAMLパーサーと衝突する — スクリプト内容は別ファイル（.sh/.py）に切り出すべき
- [tip] 複数PCのcron一元化ならGitHub Actions + Secretsを使用 — ローカルcronは廃止、Actions実行日時を月〜金に限定してレートリミットを最適化
- [pattern] Shopify Dev MCPは認証不要で即座に使用可。Admin MCPはアクセストークン・ストアURLが環境変数必須。まずDev MCPから開始する方が段階的で効率的。
- [gotcha] dotfiles更新時は既存のrebase等状態を先に完了させてから新しい変更をコミット。git状態確認→変更待避→rebase完了→追加コミット の順序が重要。
- [pattern] MCPやpermissions等の配列設定は全置換せず、既存内容を保持したまま新要素を統合・追加するapproach。
- [gotcha] セットアップスクリプトで作成したシンボリックリンクは、git の push/clone 後や同期操作で実ディレクトリに置き換わることがある。`ls -la ~/.claude/learnings` で定期確認が必要
- [pattern] auto-memory で複数ディレクトリ間の同期が必要な場合、symlink より hardlink（inode同一）が robust。memory/ で実績あり
- [gotcha] 夜間バッチで自動書き込みされるファイルが symlink 経由の場合、symlink の壊れを検出できない。バッチの最後に「書き込み先が期待通りか」を検証する guard clause が必要
- [gotcha] symlink が実ディレクトリに変わると Stop hook が沈黙に失敗し、セッション学習が dotfiles に入らず複数 PC で同期されない。symlink を定期検証すること
- [pattern] dotfiles symlink + GitHub → セッション終了 Stop hook で自動 commit/push → 次セッション開始時 pull で即時反映。別PC間同期はセッション境界で完結
## 2026-04-24 22:41 | dotfiles
- - [tip] dotfiles など共有リポジトリの同期は startup フック時点で行うと、毎セッション最新コード保証。UserPromptSubmit フックの二重実行は避ける。
- [pattern] - [gotcha] pull 前に未コミット変更をチェック。ff-only でもコンフリクト時は警告停止し、自動実行で安全性を損なわない。
- [pattern] 完了しました。変更内容:
- [pattern] 作業: 毎晩のあなたのブラッシュアップですが、いかにトークンを使用せず、シェルやスクリプトを作成して、起動させるだけの状態になるように、毎晩見直して欲しいです。
- 完了: 完了しました。変更内容:
- [gotcha] - レートリミット消費を避ける → nightly reviewをレートリミットリセット後に実行したい？
- - [tip] レートリミット（5h/7d）を避けるなら、実行スケジュール `0 3 * * 1-5`（月〜金のみ）にして週末を除外。5h リセット（AM8:00）より前に実行でき、7d は土日の消費がないため月曜朝時点で0%から開始できる
- [gotcha] **WRONG** (replaces existing permissions):
- [open] 1. Stop フックでlearningsのタグ品質チェック — セッション終了時に `[open]` が残っている項目をサマリー表示（未解決の課題を見逃さない）
- [open] `[open]` 未解決項目のチェックの話ですね。
- [pattern] Discord webhook URLを教えてください。GitHub ActionsのSecretsに `DISCORD_WEBHOOK_URL` として登録する必要があります。
- [pattern] Discord webhook URL を教えてもらえれば、`! gh secret set DISCORD_WEBHOOK_URL` で登録できます。
- 作業: あなたがshopify 改修で使えそうなプラグインやMCPなどしらべてみて
- 完了: 設定を追加しました。次に dotfiles を同期します。
- 作業: 自己ブラッシュアップと、複数PC間での設定共有について点検して欲しいです。
- 完了: git -C ~/dotfiles commit -m "fix: learningsシンボリックリンク修復・ローカル差分マージ"
- [gotcha] ### ❌ 問題: `~/.claude/learnings/` がシンボリックリンクでなくなっている
- 今回の根本原因（symlink→実ディレクトリへの変化）を防ぐために `setup.sh` を再実行するか、定期的に symlink チェックを入れると安心です。必要なら追加しますか？
- [pattern] └─ git pull --rebase (セッションにつき1回のみ)
- [pattern] → git pull --rebase
- [correction] 完了: 修正完了。886行追加（ローカルにあった未同期の学習ログをdotfilesへマージ）しました。
## 2026-04-24 11:56 | mimc-mailmagazine
- [gotcha] - RANKING（No.1〜5）
- [open] 要確認: 各商品画像は `0414_01.jpg` 〜 `0414_05.jpg` としています。実際にアップロードされる画像ファイル名と異なる場合は差し替えをお願いします。
- [gotcha] - **RANKING**（No.1〜5）
- [open] - No.4 ナチュラルトリートメントアップチャージ: SKUの対応が不確かで要確認
- 完了: `260414.html` を作成しました。
- [pattern] No.1〜5すべてのラベルをボーダー付き `<span>` スタイルに修正しました。
- [correction] 以下のコードを参考にして修正してください
- [pattern] 完了しました。全5商品のラベルが「画像の下・商品名の上」に配置されました。
- [pattern] スクリプトが正しく動作しませんでした。直接Editで修正します。
- [gotcha] 6箇所変わりましたが、CAMPAINGボックスの「特設サイトはこちら」も含まれている可能性があります。確認して戻します。
- [gotcha] - RANKING見出しサブテキスト ✅
- 完了: 完了しました。全5商品のラベルが「画像の下・商品名の上」に配置されました。
- 5. スペシャルクーポン BOX（4月30日まで）+ 注意事項
## 2026-04-09 11:08 | mimc-mailmagazine [ai]
- [pattern] メールマガジンHTML新規作成時は既存テンプレートと関連配信HTML（前回分など）を確認して構造と画像パスを把握してから実装する
- [gotcha] 画像ファイル名を仮置きする場合、実装後に実際のアップロード名と照合して差し替えが必要
- [gotcha] メールHTML複数版で同じ商品SKUが異なるalt文や画像ファイルに紐づくことがある。流用時は「SKUが一致」だけでなく、画像の中身と商品説明の整合性を確認してから採用判定する
- [pattern] 既存ファイルから画像を探す際、grep で全ファイルから対象SKUをマッピング検索し、複数ファイル間の一貫性を確認してから流用可否を判断
- [gotcha] メルマガHTMLで商品画像を再利用する場合、SKUと商品名とaltテキストの整合性を確認必須。SKUが同じでもaltが異なると誤った画像が使われる可能性がある
- [pattern] 複数メルマガ間で画像資産を流用する際、参考メール（前月等）のHTMLをgrepで検索してSKU→画像のマッピングを確認し、現在のメルマガの商品説明と照合する手順が有効
- [gotcha] メルマガ間でSKU・商品名と画像ファイルの対応が一致していないことがある。流用時は画像の中身が正しいか確認が必須
- [pattern] 複数メルマガから商品情報を流用する際は、先に全ファイルをgrepで商品SKUを検索し、対応関係を地図化してから着手
- [tip] alt属性が異なるバージョン間では、SKUと商品URLの紐付けで正規化を図る（alt文字列だけに頼らない）
- [gotcha] 複数メルマガ間でSKU・商品対応が不統一。画像流用は全件検索後にユーザー確認 → 実装の順でないと修正コストが増える
- [pattern] 複数商品の画像流用が必要な場合、先に全ファイルをgrepで検索一覧化してから、ユーザーの確認を得てから実装する
- [gotcha] メールの商品ランキング作成時、複数メール間でSKU対応が異なる可能性がある。既存メールから画像流用する際は画像の中身を確認してから置き換えること
- [pattern] メールクライアント互換性を考慮したランキング番号ラベルは `<span style="font-size: 11px; border: 1px solid #333; padding: 4px 8px; display: inline-block; margin-bottom: 0.4em; line-height: 1; vertical-align: bottom;">No.1</span>` で実装
- [gotcha] SKUと画像ファイルの対応が不確か。既存メールから流用する際は、SKU番号が同じでも用途や商品説明が異なる可能性があり、画像の内容確認が必須。
- [pattern] メルマガHTML作成時は、同時期や関連メールから画像・スタイルを流用してアセット作成を最小化。流用前に商品情報との整合性をマッピングで確認。
- [correction] HTMLメールのラベル表示など、PDFで指定された視覚的フォーマット（font-size、border、padding等）は厳密に適用。メールクライアント互換性に直結。
- [gotcha] HTMLメール実装は視覚的デザイン確認が必須。ラベル位置・ボタンUIなどPDFと一致していることを視覚検証してから実装完了と判断する
- [pattern] 新規メール制作時は複数の既存テンプレート（260401, 260410など）から構造・画像パスの参考源を先に確認してからコーディング開始
- [correction] 商品画像SKUが複数メルマガで食い違うことがある（gM1CR-03001の説明が異なる）。既存リソース流用時はファイル名だけでなく中身の確認が必須
- [gotcha] メールテンプレート：同じSKU（例 `gM1CR-03001`）が複数ファイルで異なる商品名に紐づく場合がある。画像流用時は alt テキストだけでなく実画像の中身確認が必須
- [pattern] HTML メール修正は見た目確認だけでなく、PDF仕様書の配置（画像とタイトル間）・スタイル詳細（border/padding）・UIを厳密に確認してから実装する
- [pattern] 複数変更を一度に加えず小分けにして各段階でユーザー確認を挟む（後から「変更前に戻して」は修正リスク増加）
- [gotcha] メルマガHTML制作で既存ファイル（260410等）から画像流用する際、SKUが複数メール間で異なる商品を指す可能性がある。盲目的にSKU検索のみで判断せず、実際の商品名・説明を確認して対応。
- [correction] PDFデザイン参考時、ラベル表示位置・ボタンUI等の細部仕様を最初から完全に理解してからコード作成開始する。視覚位置のズレや形状違いは修正ループを増やす。
- [pattern] メールHTMLのUI要素（ラベル、ボタン）は、メールクライアント互換性を考慮した実装パターンを参考コード例として確保し、デザイン↔実装ギャップを未然に防ぐ。
- [pattern] メルマガHTMLコーディング時は複数の既存テンプレート（260401, 260410等）を参照し、再利用可能な画像・構造を特定する。商品SKUでマッピングして流用判定。
- [gotcha] 同じSKUが異なるメール間で異なる商品説明を持つことがある。画像流用時は必ず内容確認が必要（alt テキストと実際の商品が一致しているか検証）。
- [tip] メール HTML のラベル・ボタンUIはインラインスタイルで細かく指定（`border`, `padding`, `display: inline-block`）。メールクライアント対応を前提に PDF デザインと正確に合わせる。
## 2026-04-20 01:31 | imrcry.jp
- 2. 指示書 (5) の「使用する時の注意点 1-2. ルータへのIPv6アドレス配布方法」は画像と判断しています（該当セクション近傍にHTML本文の該当表記はなし）。画像差替え扱いでよいですか？
- [correction] 作業: 修正指示書です。
- 完了: **hisawo130/imrcry.jp#2** を main にマージしました（ブランチは自動削除済み）。
- [correction] 修正B (5) 使用する時の注意点 → HTML本文に対象なし（画像扱いなら支給待ち）
- 完了: - [pattern] HTMLテキスト修正と画像差替えを明確に分離し、テキスト修正を先にマージ → 画像受領後に別PR対応で衝突リスク削減
## 2026-04-20 01:31 | imrcry.jp [ai]
- [pattern] 修正指示書を受け取ったら最初に「自分で対応vs外部支給」の判断をし、ユーザーに確認する。作業範囲がはっきりして、スコープ外の期待値ズレを防げる。
- [gotcha] 指示書に「画像修正」と書いてあってもHTMLに該当テキストがなければ対象外。実ファイル検証なしに判断すると、後で修正対象外と判明する罠。
- [pattern] 複数ファイルのテキスト置換はPython one-linerを使う方が効率的。sed/awkより扱いやすく、ミスが少ない。
- [pattern] 画像・PDF等の外部ファイルと変更を分離PRにすることで、ファイル競合を避けられる。修正指示の段階で「本セッション対応」と「外部支給待ち」を明確に分類。
- [gotcha] スプレッドシート指示の「画像で修正」は実際に拡大確認が必須。最初の分類が外れることがある。
- [pattern] 複数ファイルの定型修正（スペース削除、title更新等）はPythonone-linerで一括処理。手作業より確実で効率的。
- [pattern] 複合修正タスクは実装前に「外部依存」「本セッション対応」に二分分類 — 修正指示書受領直後にスコープを確定することで、画像・PDF新版受領後の統合作業の曖昧性排除＆PR戦略明確化。
- [gotcha] 別ファイル差し替えはHTML参照URL不変なら競合なし — 画像/PDF同名差し替え時、`<img src>` を変更しない限りHTMLテキスト修正との競合ゼロ。独立したPR化の根拠。
- [tip] 仕様曖昧時は実物（スクショ/PDF）を拡大確認 — 「修正対象か否か不明」な場合、推測より実物確認。画像拡大読み取りで修正スコープ確定。
- [gotcha] 修正対象の場所（テキスト vs 画像）が不明確な時は、HTMLテキスト検索 + 画像拡大読み取りの2段階確認が必須。どちらか一方だけだと見落とし。
- [pattern] 異なるファイル形式（HTML / JPG / PDF）の修正は別々のPRにすると競合なし。「齟齬が出ないPRだけマージ」の指示がある時に有効。
- [tip] 大量の同種テキスト修正（スペース削除など）は multi-edit.py より Python one-liner の方が記述・確認・実行が快適。
- [gotcha] Excel修正指示書の画像/テキスト判定 — 「修正対象」に見えても、HTML本文に該当テキストがなく画像に埋め込まれていることがある。セクション近傍のHTML本文を実際に確認してから外部支給判定すること。
- [pattern] 異なる目的の修正は初期計画で分割コミット化 — IPoE表記統一、スペース削除、メタタグ修正の3つの目的ごとにコミット分割すると、git logから後年修正背景が追いやすく、部分リバートも容易。
- [tip] 想定ツール未作成時は即座にone-liner代替 — `multi-edit.py`が存在せず、Python one-linerで複数ファイルの一括find-replaceを実行。ツール確認は事前に、なければ軽量な代替手段を用意。
- [pattern] 修正指示書から、HTML本文テキスト修正と画像・PDF差し替えを早期に分類。画像内のテキストは後者に該当し、修正不可能なため先に整理することで、実装範囲を明確化できる
- [gotcha] 複数ファイル一括編集が必要な場合、使用予定のツール（multi-edit.py等）の存在を実装開始前に確認。未作成なら early に Python one-liner 等の代替手段に切り替える
- [pattern] テキスト修正のPRと画像差し替えを並行作業する際、ファイル拡張子の分離（.html vs .jpg/.pdf）を確認しておくと競合リスクなくマージ判定が可能
- [gotcha] Excel修正指示書の「修正箇所」と「実際の画像内容」が不一致の可能性 → 画像を実際に拡大確認して判断する必要がある
- [pattern] HTMLテキスト修正と画像差替えを明確に分離し、テキスト修正を先にマージ → 画像受領後に別PR対応で衝突リスク削減
- [tip] 性質が異なる修正（IPoEテキスト→製品名スペース→titleタグ）を3段階コミットで分離 → 各段階で独立した検証・ロールバック可能
- [gotcha] `~/.claude/tools/multi-edit.py` が存在しない環境では、Pythonワンライナーでのbulk編集で対応（複数ファイル同時修正が必要な場合）
- [pattern] HTML修正と画像/PDF差替えを分離してPR化すると、新版ファイル支給後も競合しない（別ファイルの上書きなため）
- [tip] 修正指示書をExcelで読み込み時点で「実装可能（テキスト）/ 支給待ち（画像・PDF）」に分類することで、スコープ確定と納期調整が早期にできる
## 2026-04-13 11:49 | bouquet [ai]
- [gotcha] マルチチャネル表記統一では外部媒体（Google Map等）の登録状況を優先に判断し、自社サイトを外部に合わせる方が効率的でリスク低い。
- [pattern] 複数の正解がある課題は、各案のトレードオフを明確にして提示すると、ユーザーが判断しやすい。
- [tip] ビジネス登録（Google Map、HPB等）は検索SEO・口コミに影響するため、登録名を「正式名」の源流として扱うべき。
- [pattern] 複数チャネル運用で表記統一する際は、外部媒体の既存登録データを優先し自社サイトを合わせる方が、変更手数が少なく既存実績を活かせる。
- [gotcha] 複数メディア（Google Map、HPB等）に既に登録されている正式名は変更コストが高い。口コミ・検索実績が積み上がるため、自社サイトを外部媒体に合わせるのが現実的
- [pattern] マルチチャネルのデータ統一では、先に「どこが権威か」「どこの変更コストが最高か」を判定してから、その媒体に自社情報を合わせる戦略が効率的
- [gotcha] SSRサイトのスクレイピングはJSレンダリング後のコンテンツが取得できない場合がある。コードから直接データを抽出する方が確実。
- [pattern] URLリダイレクトやクエリパラメータから情報を抽出する際、URLデコード+正規化で複数の表記パターンを統一できる。
- [tip] 外部媒体（Google Map・HPB等）の登録名は検索・口コミが積み上がっているため、自社サイトを外部に合わせる方が現実的。逆向き更新は手間。
- [gotcha] SSR環境でJSレンダリング後のコンテンツが取得困難な場合、web fetch前にコードベース（Vue・JSON設定）から直接URL やデータを抽出する方が効率的。構造化データは code-first で確認。
- [pattern] Google Map・ビジネスプロフィールから店名情報を取得する際、URLパラメータ（qパラメータなど）に店名がエンコード状態で含まれていることがあり、URLデコード処理で情報抽出可能。
- [gotcha] 複数の外部媒体（Google Map・HPB・ビジネスプロフィール）は店舗ごとに表記がバラバラで統一されていない可能性が高い。統一ルール決定前に全店舗の外部登録内容を確認し、既存パターンを把握してから方針立案すべき。
## 2026-04-13 11:49 | bouquet
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/bouquet/pages/gym/gym-akasakamitsuke.vue in the IDE. This m
- 完了: 作成しました。
- 完了: Notionを更新しました。
## 2026-04-14 10:23 | pietro-onlineshop_dev
- 作業: 本番環境へのデプロイを手伝って欲しいです
- 完了:    → これらを本番に含めますか？含める場合は `main` にマージしてからデプロイします。
- 完了: 1. **`cdx/temperature-profile-totals` の3コミット**（温度帯送料判定テスト等）は今回の本番に含めますか？含める場合は先に `develop` へマージが必要です。
- 作業: 学習ログ抽出システムです。以下のClaude Codeセッションから、将来同様の問題で悩んだ時に役立つ学びを抽出してください。
- 完了: - [pattern] Shopifyアプリデプロイ前に、ブランチ先行状態とマージ予定を確認し、リリース範囲を明確化する
- ⚠️ 注意: `shopify auth login` が必要な場合は対話操作が発生します。その場合は `! shopify auth login` をターミナルで実行してください。
- 完了: 2. `develop` を `main` にマージ
- [gotcha] コード上 `input.discount.discountClasses` に `SHIPPING` が含まれないと即 `{operations: []}` を返す設計です。アプリを削除・再作成したことで既存のディスカウントも消えています。
- [gotcha] discountClasses: [SHIPPING]
- [gotcha]    - `[gotcha]` — 罠・NG・禁止・バグ・エラーの原因
## 2026-04-14 10:23 | pietro-onlineshop_dev [ai]
- [pattern] Shopifyアプリデプロイ前に、ブランチ先行状態とマージ予定を確認し、リリース範囲を明確化する
- [gotcha] 本番デプロイ時に`shopify.app.<config>.toml`で環境を指定するステップを忘れやすい—手順チェックリストに含める
- [tip] 複数ブランチが並行している場合、デプロイ前に全ブランチのコミット差分を`git log main..develop`で可視化してから確認質問を出すと齟齬が減る
- [gotcha] 本番デプロイ時に複数ブランチが存在する場合、「どのコミットをリリースするのか」を明確にしないまま進めると誤デプロイのリスク。必ず状態整理と確認を分けて行う
- [pattern] デプロイ前の流れ：状態整理（各ブランチのコミット差分）→ マージ計画の確認 → 実行手順の明示 → 明示的な「進めてください」許可待ち
- [gotcha] Shopify アプリのデプロイ前に、複数ブランチ（main/develop/feature）の状態とコミット差分を確認し、本番に含めるコミット範囲を明確に判断する必要がある。
- [pattern] Shopify アプリのデプロイ手順がドキュメント化されていれば、デプロイ前に参照して手順を確認・チェックできる。
- [tip] 本番デプロイ後、本番アプリダッシュボード URL と設定ファイルの client_id を照合することで、デプロイの正確性を検証できる。
- [gotcha] 本番デプロイ前に含めるコミット範囲とマージ戦略を複数回確認してからマージを進める
- [gotcha] 「アプリ削除」と「アンインストール」は対応が異なるため、事前に区別して確認する必要がある
- [pattern] デプロイ手順書に確認チェックリスト（含めるコミット、設定ファイル、client_id 検証）を組み込む
- [gotcha] Shopifyアプリが削除・再作成されたら`client_id`が変わる。`shopify app config link`で新アプリにリンク直しが必須
- [pattern] 本番デプロイ前に全ブランチの状態確認（main/develop/feature）を実施。含めるコミット、除外するコミットを明示的に確認
- [tip] Partner Dashboardでのアプリ削除とストア管理画面でのアンインストールは別。前者は新規アプリ作成、後者は再インストール可能
- [gotcha] Shopifyアプリを削除・再作成した場合、`client_id`が変わるため`shopify app config link --config <toml>`で新アプリに再度紐づけが必須
- [pattern] 本番デプロイ前に過去削除された拡張機能の履歴を確認し、削除警告に備える（Removing extensions警告は既削除データに対しては無視可）
- [tip] `shopify app deploy`は対話操作が必要なため、自動化できず手動ターミナル実行が必須
- [gotcha] Partner Dashboardでアプリ削除後の再作成時、client_idが変わるため`shopify app config link`で新アプリに紐づけ直す必要がある
- [tip] リポジトリから削除済みのextensionをデプロイする際の警告は、アプリを再作成している場合はユーザーデータ既消のため`Yes`で進めて問題ない
- [gotcha] Shopify Partner Dashboard でアプリ削除すると新しいアプリ作成・client_id が変更される。デプロイ失敗時は client_id 変更が原因の可能性。
- [pattern] アプリ連携変更時は `shopify app config link --config <toml>` でリンク直し。Partner Dashboard のアプリ一覧から選択すると client_id 自動更新。
- [pattern] Shopify アプリ再作成後のインストール：Dev Dashboard の "Install app" からインストール URL 取得→本番ストア実行。既存インストール有れば新版自動適用。
- [gotcha] Shopify アプリ削除・再作成後、新しい client_id が生成される。デプロイ前に `shopify app config link` で config ファイルを新アプリに紐づけ直す。
- [pattern] `shopify app deploy` で削除済みエクステンション警告が出ても、アプリ自体が既に削除・再作成されていればデータは消えており、Yes で進める。
- [tip] `shopify app deploy` は対話操作が必要なため、バッチ実行せず直接ターミナルで実行する。
- [gotcha] Shopifyアプリをダッシュボードから削除・再作成するとclient_idが変わり、config紐づけが無効化される。デプロイ前に `shopify app config link` で再紐づけが必須。
- [pattern] 削除済みエクステンションについてのデプロイ警告は、アプリ自体が一度削除・再作成されている場合はユーザーデータ既に消失しているため進行可能。
- [tip] `shopify app deploy` は対話操作が必須のためClaude内で実行できない。本番デプロイはターミナルで直接実行すること。
- [gotcha] Shopifyアプリ削除・再作成時、`client_id`が変わる → `shopify app config link`で設定ファイルを新アプリに再リンク必須
- [pattern] 本番デプロイ時は、未マージコミット確認 → `main`へマージ → `shopify app deploy` → 本番アプリURL + `client_id`照合で検証
- [gotcha] アプリ削除によりDiscount設定も消滅 → Function は管理画面でDiscount再作成まで動作しない（`input.discount.discountClasses`が空）
- [gotcha] アプリを削除・再作成すると`client_id`が変わり、既存の割引ディスカウント・Function設定が全てリセットされる — 初期設定から再構築が必要
- [gotcha] FunctionコードがFunction ハンドラで割引クラスをチェックしており、割引未作成＝Function未動作となる隠れた依存関係 — デプロイ後の動作確認時に注意
- [pattern] 複雑な送料判定ロジック（金額帯×地域×温度帯）は最大値（¥11,000以上）から始めるのが検証効率が高い
- [gotcha] Shopify アプリを削除・再作成するとすべての関連データ（ディスカウント、カスタム設定等）も削除される。再デプロイ後は初期設定を完全にリセットする必要がある。
- [pattern] Function のデプロイ時に「Removing extensions」警告が出ても、アプリ既存削除済みならそのエクステンションのデータも既に消えている。安全に確認プロンプトで Yes で進められる。
- [tip] Shopify Function デプロイ後に機能が動作しない場合、Function の入力条件（ディスカウント存在確認など）が満たされているか先に確認する。Function は前提データなしでは動作しない。
- [gotcha] Shopify アプリを Partner Dashboard で削除・再作成すると、割引ディスカウント等のリソースデータが消える。Function は Deploy されても入力データがないため動作しない。GraphiQL で functionId と `discount.discountClasses` を確認して診断する。
- [pattern] Shopify アプリデプロイ後の確認手順は、Deploy 成功 → Install app（既インストール時は自動適用） → カート動作確認（Function の入力データ含む）の順。
- [tip] アプリ削除後の再インストール時は、`shopify app config link` で新しい `client_id` を自動取得できる。手動入力より確実。
- [gotcha] Partner Dashboard でアプリを削除・再作成すると、Function による割引設定も消失する。デプロイ後は管理画面でディスカウント・キャンペーンを再作成してから機能テストを実施する必要がある。
- [pattern] アプリ再作成後は必ず `shopify app config link --config <config-file>` で新しい client_id に紐づけ直す。設定ファイルの client_id が自動更新されることを確認してからコミット。
- [tip] Function が条件を満たさない場合は即座に `{operations: []}` を返す設計になっている。稼働チェックリストに「管理画面でディスカウント作成・有効化」を含める。
- [gotcha] アプリ削除・再作成時、Partner Dashboard上で新規アプリ作成 → shopify app config link で紐付け。新client_idが自動更新されるため、この変更をコミット・デプロイが必須
- [pattern] Functionデプロイ後はコード検証のみでなく、管理画面でディスカウント設定を作成 → 実カートで割引反映を確認する実動作検証が必須
- [tip] 割引が機能しない場合、まずGraphQL APIで installed_functions を確認してFunction正常性を診断してからコード疑いに進む
- [gotcha] Shopify アプリ削除・再作成時は新しい `client_id` が生成される。`shopify app config link` で `.toml` を再リンク必須。
- [gotcha] Function 型ディスカウントのコードがリポジトリにあってもデプロイ後は、管理画面で実際にディスカウントを作成・有効化しないと Function が動作しない。
- [pattern] Shopify アプリ削除・再作成後の Function エクステンション削除警告は無視可能（アプリ削除でデータ既消失）。
- [gotcha] アプリ削除後の Function デプロイで「Removing extensions can permanently delete app user data」警告が出ても、アプリ自体がもう消えていればデータは既に消えているため Yes で進める判断できる
- [gotcha] アプリを削除・再作成すると Shopify Admin で作成したディスカウント設定も消える。Function デプロイ後に管理画面で初期設定（ディスカウント作成）を改めて実行する必要がある
- [pattern] アプリ削除後の復旧：`shopify app config link` で新 client_id に再紐づけ → デプロイ → 管理画面で初期データ再構築、という手順で完全復旧できる
- [gotcha] Shopify アプリ削除→再作成時、client_id が変わるだけでなく、関連する全ディスカウント・設定もリセットされる。再インストール後は初期設定をやり直す必要がある。
- [gotcha] Function のコードが完璧でも、実行時に必要な GraphQL データ（ディスカウント等）がないと即座に空を返す。Function デプロイと管理画面での設定作成は別タスク。
- [pattern] Shopify アプリ本番デプロイは config link（client_id 同期）→ コミット → develop/main マージ → deploy の順序で実行する。
- [gotcha] Shopify パートナーダッシュボードでアプリを削除すると新しい `client_id` が生成されるため、`shopify app config link` で config ファイルを再紐付けする必要がある。
- [gotcha] アプリの削除・再作成により Shopify Admin 側のディスカウント設定も消えるため、Function が GraphQL 入力を受け取れず動作停止する。Admin 画面でディスカウントを再作成する必要がある。
## 2026-04-14 09:32 | pietro-app
- [pattern] `main` へのマージ・プッシュが完了しました。最後に `shopify app deploy` を実行します。
- 完了: `main` へのマージ・プッシュが完了しました。最後に `shopify app deploy` を実行します。
## 2026-04-14 09:32 | pietro-app [ai]
- [gotcha] Shopify アプリを Partner Dashboard で削除した場合、新しい client_id が生成される。設定ファイルを `shopify app config link` で再紐づけしないとデプロイ失敗。
- [pattern] デプロイ前に main と develop の先行状況を確認し、どのコミットをリリースするか明確にしておくと、ロールバック判断やミス防止が容易になる。
- [tip] Shopify アプリの config link は対話操作が必須のため、自動化できない。ユーザーに明確に手順を指示し、完了後に確認を取ることが重要。
- [gotcha] Shopifyアプリを削除・再作成すると client_id が変わる。デプロイ前に `shopify app config link` で新アプリに紐づけ直して client_id を更新する必要がある。
- [pattern] `shopify auth login` や `shopify app deploy` など対話操作が必要なコマンドはClaude Codeから実行できない。ユーザーにターミナルで直接実行するよう指示する。
- [tip] 本番デプロイ前に develop と main の差分を列挙し（コミット数・内容），リリース範囲を明示的に確認して認識を合わせる。
## 2026-04-14 11:53 | pietro-onlineshop_ver01
- ### 1. `stopImmediatePropagation()` will NOT break other document handlers ⚠️ Medium confidence
- ### 2. Race condition before `discountDeckInstance` init — popup may silently fail to open ⚠️ High confidence (gotcha)
- ### 4. Metafield `!= blank` check is unreliable for empty arrays/lists ⚠️ High confidence (gotcha)

## 2026-04-15 21:50 | teras-taya [ai]
- [gotcha] Shopifyの `complementary_products` メタフィールドに当該商品自身が含まれる場合がある。ループ内で `product.id` との重複チェックでスキップ必須。
- [pattern] Shopify theme で `settings_data.json` は自動同期により変更される。PR作成時は事前に確認し、必要に応じてマージ時に `main` と同期させる手順を用意。
- [tip] メタフィールドデータをテンプレートで使う前に、バリデーション・フィルタリングステップを入れるとデータ品質の問題に強くなる。
## 2026-04-24 22:36 | dotfiles [ai]
## 2026-04-24 22:41 | dotfiles
- [gotcha] 完了: git -C ~/dotfiles commit -m "fix: learningsシンボリックリンク修復・ローカル差分マージ"
## 2026-04-24 11:56 | mimc-mailmagazine
- [gotcha] 5. スペシャルクーポン BOX（4月30日まで）+ 注意事項
## 2026-04-09 11:08 | mimc-mailmagazine [ai]
## 2026-04-20 01:31 | imrcry.jp
- [gotcha] 2. 指示書 (5) の「使用する時の注意点 1-2. ルータへのIPv6アドレス配布方法」は画像と判断しています（該当セクション近傍にHTML本文の該当表記はなし）。画像差替え扱いでよいですか？
## 2026-04-20 01:31 | imrcry.jp [ai]
## 2026-04-13 11:49 | bouquet [ai]
## 2026-04-13 11:49 | bouquet
## 2026-04-14 10:23 | pietro-onlineshop_dev
- [gotcha] ⚠️ 注意: `shopify auth login` が必要な場合は対話操作が発生します。その場合は `! shopify auth login` をターミナルで実行してください。
## 2026-04-14 10:23 | pietro-onlineshop_dev [ai]
## 2026-04-14 09:32 | pietro-app
## 2026-04-14 09:32 | pietro-app [ai]
## 2026-04-14 11:53 | pietro-onlineshop_ver01
- [gotcha] ### 1. `stopImmediatePropagation()` will NOT break other document handlers ⚠️ Medium confidence
- [gotcha] ### 2. Race condition before `discountDeckInstance` init — popup may silently fail to open ⚠️ High confidence (gotcha)
- [gotcha] ### 4. Metafield `!= blank` check is unreliable for empty arrays/lists ⚠️ High confidence (gotcha)

## 2026-04-14 18:45 | pietro-onlineshop_ver01 [ai]
- [gotcha] Liquid の `!= blank` は JSON 文字列 `"[]"` を空でなく判定。メタフィールド型を Shopify 管理画面で確認し、必要に応じて明示的な空文字列チェックを実装する
- [pattern] 非同期初期化タイムアウト時はコンソール警告ではなく、ユーザーフィードバック（トースト等）を必ず追加してサイレント失敗を防ぐ
- [gotcha] `stopImmediatePropagation()` は同一ノード上の後続リスナーのみ抑制。異なるノード（`body` vs `document`）のリスナーは影響しない
- [gotcha] Liquidの`!= blank`はJSON文字列には効かない。metafieldが`"[]"`形式で返る場合、空配列判定は失敗し、意図しないリンク表示になる。Shopify admin で実型確認必須。
- [gotcha] `stopImmediatePropagation()`は同一要素の後続リスナーのみ抑止。異なるノード（document vs body）のリスナーは影響を受けず、モーダルクローズは無関係。
- [pattern] ポーリング/初期化待ちのタイムアウトはコンソール警告だけでは silent failure。ユーザー向けのトースト/アラートで失敗を即座に通知し、リトライループを防ぐ。
- [gotcha] Liquidの`!= blank`はメタフィールドの実データ型に依存する；JSON文字列`"[]"`は空配列として扱われず`blank`判定に失敗する。必ずShopify管理画面で実構造を確認し、型に応じた明示的チェック（`!= "[]"` など）を追加する
- [gotcha] 初期化タイムアウト時はコンソール警告のみで、ユーザーフィードバック（toast/alert）がないため、UIが無応答に見える。ポーリング待機中の再クリックで隠れた複重リクエストが発生する可能性
- [pattern] jQueryの名前空間付きイベント（`click.discountDeck`）は外部スクリプトとの衝突リスク。`.off().on()`で原子的に更新する方法は有効だが、コード内で同一namespace登録がないか事前検証が必須
- [gotcha] Liquid `!= blank` でメタフィールド（JSON形式）の空配列チェックは失敗。`"[]"` 文字列と null を区別しない場合がある。実装前に Shopify admin で実際の型を確認が必須。
- [gotcha] `stopImmediatePropagation()` は同一要素の後続リスナーのみを抑制。祖先/子孫要素のリスナーは影響しない。「ドキュメント全体のクリック止める」と誤解しやすい罠。
- [gotcha] ポップアップ初期化タイムアウト（console.warn のみ）はサイレント失敗。ユーザーは成功と誤認し、再クリックで隠れたポーリングが多重発動。UI フィードバック（toast）が必須。
- [gotcha] `<span>`内に`<div>`を置くのはHTML規仕違反。行366の条件分岐で使用中の`<span class="title">`は正しい実装。テンプレート記述時に要確認。
- [gotcha] `pointer-events: none`はアクセシビリティ問題（テキスト選択不可）。代わりに明示的なホバーリセット（cursor + inherit）を使う。
- [pattern] ポーリング+タイムアウト時は、console.warnだけでなくUIトースト/エラーメッセージでユーザーに通知。現在は行797で無音フェイル。
- [pattern] Hover状態の無効化：`pointer-events: none` ではなく `cursor: default` と `:hover` で color/opacity/text-decoration をリセット。アクセシビリティとテキスト選択を保持できる
- [gotcha] インタラクティブな `<span>` には `role="button"` 、`aria-label` 、Enter/Space キーハンドラが必須。キーボード操作不可だとスクリーンリーダー環境で機能しない
- [gotcha] Shopify metafield は null/undefined チェック必須：`customer.metafields.*.*.value` は常に blank チェック（Liquid）で防御的に実装しないとエラー化
- [gotcha] `<span>`をボタンとして使う場合、`role="button"`と`aria-label`が必須。ARIAなしはスクリーンリーダー利用者に見えない。
- [gotcha] Shopify Liquidでのメタフィールドアクセス時、`!= blank`だけでなく段階的チェック推奨。ドット表記の深いアクセスはundefinedを返す可能性あり。
- [pattern] イベントハンドラ競合防止には`stopImmediatePropagation()`が効果的。`stopPropagation()`との違い理解（親への伝播 vs 同一要素の別ハンドラ）が重要。
- [pattern] `stopImmediatePropagation()` でメニューのハンドラーとの競合を回避。意図をコメント明記し保守性向上。
- [pattern] ポーリング時に `window.isPolling*` フラグで再入場を防止。重複実行とメモリ漏洩を一行で解決。
- [gotcha] Timeout 時に `console.warn` のみで UI フィードバックなし。ユーザーは気づかず UX 低下。
- [gotcha] 非同期処理がタイムアウト時に console.warn のみで、ユーザーへの視覚的フィードバックがない → トースト通知など必須
- [gotcha] Liquid メタフィールドチェック `!= blank` だけでは親の `metafields` オブジェクト自体が undefined の場合に対応できない → 多段階の null 安全性確認が必要
- [gotcha] click ハンドラー付き `<span>` に `role="button"` と `aria-label` がないとスクリーンリーダー非対応＆キーボード操作不可
- [gotcha] `pointer-events: none`はテキスト選択とスクリーンリーダーを破壊する。代わりに明示的なホバーリセット＆cursor指定を使う。
- [gotcha] タイムアウト時にコンソール警告だけでなく、トースト/警告通知でユーザーにフィードバックを必ず表示する。
- [gotcha] `<span>`にクリックハンドラを付けるだけではアクセシビリティ非対応。`role="button"`, `aria-label`, Enter/Space キーハンドラが必須。
- [gotcha] `<span>` 要素に click handler を設置する場合、`role="button"` と `aria-label` が必須。ARIA なしだと screen reader が認識できず、キーボード操作も不可
- [gotcha] Liquid の `metafields.x != blank` 条件は metafield 自体が undefined の場合をカバーしない。メタフィールド操作時は存在確認を明示的に追加する
- [pattern] Polling/非同期操作のタイムアウトで console.warn だけでなく、UI フィードバック（トースト、モーダル等）でユーザーに通知。サイレント失敗は UX 低下につながる
- [gotcha] `pointer-events: none` は避ける — テキスト選択ブロック＆スクリーンリーダー操作に悪影響。代わりに `cursor: default` + `:hover` 明示的リセットを使う。
- [gotcha] `<span role="button">` 使用時は Enter/Space キーハンドラ必須。現在はクリックのみで、キーボード＆スクリーンリーダーユーザーが操作不可。
- [pattern] 非同期初期化のポーリングはフラグ（`isPolling...`）＋最大待機時間（5000ms）で明示的に多重実行防止＆タイムアウト処理を実装。
- [gotcha] `<span>`ボタンに`role="button"` / `aria-label`がないとスクリーンリーダー非対応。Shopifyテーマでよくある過ち。
- [pattern] 非同期初期化待機には「フラグ+ポーリング+タイムアウト管理」パターンで再エントランス防止できる。
- [gotcha] タイムアウト失敗時、コンソール警告だけではユーザーに届かない。トーストなどのUIフィードバック必須。
- [gotcha] Shopifyで`<span>`をボタン化する場合、`role="button"`と`aria-label`（またはテキスト内容）を必須とすること。スクリーンリーダーで検出不可になる
- [gotcha] ポーリング系の非同期初期化で、タイムアウト時はコンソール警告だけでなくUIに視覚的フィードバックを表示。ユーザーに無応答に見える
- [pattern] Liquidで`!= blank`チェック後でも、JSでメタフィールド値にアクセスする場合は存在チェックを追加。型安全性を高める
- [pattern] stopImmediatePropagation()を使ってイベント委譲時の親ハンドラを完全に止める（stopPropagation()では不十分）。コメント「prevents Discount Deck's handleOutsideClick」で意図を明確にする
- [gotcha] <span>のHTML semantic変更は前後でCSSの padding/margin競合を引き起こす可能性あり。スタイルシート全体を確認してから実装
- [gotcha] 非同期ポーリングがタイムアウトしても console.warn だけでは不十分。ユーザーに視覚的フィードバック（トーストやモーダル）を必ず表示する
- [gotcha] `<span role="button">` はaria-labelとキーボード(Enter/Space)ハンドラ必須。ないとスクリーンリーダー無反応・キーボード操作不可。
- [gotcha] `pointer-events: none`は避ける。テキスト選択/アクセシビリティ悪化。代わりにcursor/色をinheritで明示的にreset。
- [pattern] async初期化待ちはフラグ+ポーリング+maxWaitを併用。double-init防止 + タイムアウト自動回収 + ユーザーフィードバック追加で堅牢化。
- [gotcha] HTMLタグ変更（`<div>` → `<span>` など）時は CSS の display/padding ルールへの影響を確認。インライン vs ブロック表示の変化が レイアウト崩れを引き起こす
- [pattern] ポーリングのフラグベース再入防止——`isPolling` フラグ + 5s タイムアウト + console.warn で、非同期 API 初期化の二重実行と無限待機を防ぐ
- [gotcha] `<span>` を button のようにクリックハンドルする場合、`role="button"` + `aria-label` + Enter/Space キーハンドラが必須；click オンリーはアクセシビリティ違反
- [gotcha] `pointer-events: none`はテキスト選択を防ぎアクセシビリティ損害。代わりに`cursor: default`と明示的な`:hover`リセット使用。
- [pattern] `stopImmediatePropagation()`で親要素ハンドラ競合回避。複数デリゲートハンドラ時はchild側で明示的阻止。
- [gotcha] Liquidメタフィールド`blank`チェックは存在判定のみ。未定義値のエラーハンドリングは別途必須。
- [gotcha] `pointer-events: none` はテキスト選択・キーボード操作を阻害する。代わりに `cursor: default` と hover時の色/opacity/text-decoration リセットで実現する
- [gotcha] Liquidで条件分岐させる場合、要素型（`<div>` vs `<span>`）を統一しないと HTML spec 違反。特にネストの場合は厳格
- [gotcha] click ハンドラーを `<span>` に付ける際、`role="button"` と `aria-label` がないとキーボードアクセス・スクリーンリーダーが使えない
- [gotcha] `pointer-events: none` でアクセシビリティ破壊（テキスト選択ブロック、スクリーンリーダー無視）→ 代わりに `cursor: default` + 明示的なホバーリセットを使用
- [pattern] ポーリング再進入防止: フラグ(`isPollingDiscountDeck`) + タイマー管理(`elapsed` 追跡) + 最大待機時間でDiscountDeck非同期初期化を安全に待つ
- [gotcha] HTML要素タイプ変更時（`div` → `span`）はCSS副作用の再検査必須（フォント継承、`line-height`などの表示崩れ）
- [gotcha] クリックハンドラ付き `<span>` に `role="button"` や `aria-label` がないとスクリーンリーダーが認識できない。インタラクティブ要素には ARIA 属性が必須。
- [pattern] 外部 JS ライブラリの初期化完了待ちに `stopImmediatePropagation()` + flag-based polling + timeout (5s) が有効。標準的な統合パターン。
- [gotcha] Liquid で metafield 参照時に blank チェックなしで使うと undefined エラー。`customer.metafields.xxx` に対して常に `!= blank` で保護。
- [gotcha] Liquid で `<span>` 内に `<div>` をネストするのは HTML 仕様違反；メニュー項目と統一する場合は両方 `<span>` にする必要あり
- [pattern] 複数コンポーネント統合時は `stopImmediatePropagation()` で親要素のハンドラをブロック；ポーリング中は フラグでガード（二重実行防止）
- [tip] 非同期タイムアウト時は `console.warn` のみでなく UI にも結果を表示；ユーザーに失敗状態を通知する必要あり
- [pattern] `pointer-events: none` の代わりに `cursor: default` と `:hover` reset ルールを使う方が accessibility と text selection を保持できる
- [gotcha] `<span role="button">` で click handler を使う場合、keyboard support（Enter/Space key）がないと screen reader + keyboard ユーザーが操作不可
- [gotcha] Liquid metafield の存在チェックは conditional 内だけでなく、undefined throw を防ぐため事前 null-safety guard が必要
- [gotcha] `<span>`をボタンとして使う場合、`role="button"`と`aria-label`が必須。なければスクリーンリーダー無視される。複数Geminiレビューサイクルで指摘される典型的な見落とし
- [tip] ポーリングタイムアウト時の`console.warn`だけでなく、ユーザー向けUIフィードバック（トースト等）検討必須
- [correction] `<span role="button">` はキーボースアクセス対応が必須（Enter/Space handler + aria-label）。Gemini review で指摘されたが未実装状態。
- [gotcha] `stopImmediatePropagation()` はイベント委譲時に外側のハンドラーも止まる。コメント明記推奨（他者の変更を防止）。
- [gotcha] Liquid metafield access は null-safety 不十分。`!= blank` チェックだけでは undefined アクセス時エラー。ガード句追加を検討。
- [gotcha] クリッカブルな`<span>`に`role="button"` + `aria-label`がないと、スクリーンリーダーユーザーに操作を認識されない。Shopifyテーマではアクセシビリティが後付けされやすい。
- [gotcha] ポーリング完了時に console.warn だけでは、ユーザーに失敗が通知されない。UI フィードバック（トーストなど）を実装しないと UX が悪化する可能性がある。
- [pattern] ポーリング実装では、再入場防止フラグ + maxWait + インターバル 100ms の組み合わせが堅牢。5秒タイムアウトは実用的な目安。
## 2026-04-20 13:58 | teras-taya [ai]
- [gotcha] Prestige の `visibility: hidden` は peek 実装を構造的に不可能にする。opacity ベースのスライダーでは隣接スライド表示不可。実装前に CSS 制約を確認
- [pattern] peek 機能は scroll-carousel（スクロール型）で実装可能。opacity フェード型は非表示スライド完全に隠すため不適切
- [tip] サードパーティテーマの警告（`custom.overlay` など）は既存グループ名で問題なし。Prestige の命名規則を尊重してスキーマ追加
- [gotcha] Prestige の slideshow-carousel は CSS `position: absolute; visibility: hidden` で非アクティブスライドを隠すため、opacity フェードベースでは隣スライドの peek 実装は構造的に不可能。
- [pattern] Peek とループの実装には scroll-carousel + CSS scroll-snap + padding-inline を使用。クローンスライド追加で無限ループを効率的に実現。
- [tip] 有料テーマ使用時は既存スライド実装の CSS 設計を最初に調査してから対応方針を決める。制約を理解することで最適な解決策を判断できる。
- [gotcha] Prestige の `slideshow-carousel` は非アクティブスライドを `position: absolute; visibility: hidden` で隠すため peek（隣スライドのチラ見え）は構造的に不可能 → `scroll-carousel` + CSS scroll-snap への切り替えが必須
- [pattern] scroll-carousel で loop を実現するには最終スライドの clone を先頭に、最初のスライドの clone を末尾に追加し、`scrollend` イベントでクローン着地時にリアルスライドへ `instant` ジャンプ
- [gotcha] `<img>` 要素のブラウザネイティブドラッグは JS の drag ハンドラより発火優先度が高い → CSS `pointer-events: none` で抑制必要
- [gotcha] Prestige テーマの CSS `.slideshow__slide:not(.is-selected) { position: absolute; visibility: hidden }` は opacity フェードの peek を構造的に不可能にする。別セクション実装（scroll-snap ベース）で代替を検討
- [pattern] Swiper なし環境で carousel loop を実装するには、最終スライドを先頭に、最初のスライドを末尾に複製し、`scrollend` で実スライドへ `instant` ジャンプすることで視覚的な切れ目をなくせる
- [tip] scroll carousel で画像ドラッグ選択を防ぐには `-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` の CSS で、ブラウザネイティブドラッグハンドラを封じる
- [gotcha] Prestige の slideshow-carousel は CSS で非アクティブスライドを `visibility: hidden` で隠すため、隣スライドのチラ見え（peek）は構造的に不可能。scroll-carousel への切り替えが必要。
- [pattern] scroll-snap ベースのスライダーで最後/最初のスライドをクローンして先頭/末尾に追加し、scrollend でリアルスライドへ instant ジャンプさせることでループを自然に実現。
- [tip] 画像ドラッグ選択防止には `-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` を組み合わせる。pointer-events は親要素へのイベントをバブルさせるのでリンク機能が保たれる。
- [gotcha] Prestige の `slideshow-carousel` は非アクティブスライドを `position: absolute; visibility: hidden` で隠すため、隣スライドのpeeking は構造的に不可能。スクロールベース実装への変更が必須。
- [pattern] スクロール型カルーセルの無限ループ実装：最初と最後のスライドを clone して配列前後に挿入し、`scrollend` イベントで clone 到達時に対応する実スライドへ瞬時ジャンプさせると、視覚的に切れ目なくループできる。
- [gotcha] 画像要素のブラウザネイティブドラッグが drag ハンドラより先に発火するため、`-webkit-user-drag: none` + `pointer-events: none` で抑制が必要。クリックは親要素にバブルするため機能は維持される。
- [gotcha] Prestige の `slideshow__slide:not(.is-selected) { position: absolute; visibility: hidden }` は非アクティブスライドを完全に隠すため、peek は`scroll-carousel` など別のコンポーネントに切り替えが必須。同じ方式では構造的に不可能。
- [gotcha] スライダー内の `<img>` ドラッグはネイティブブラウザドラッグが drag ハンドラより優先。`-webkit-user-drag: none`, `user-select: none`, `pointer-events: none` で CSS 抑制が必要。
- [pattern] 最終スライド clone を先頭、最初スライド clone を末尾に配置し、`scrollend` で実スライドへ瞬時ジャンプすることで Swiper.js なしの無限ループが実現可能。
- [gotcha] Prestige の opacity-fade carousel は非表示スライド に `position: absolute; visibility: hidden` を適用するため、隣スライドのチラ見え（peek）は構造的に不可能。scroll-snap ベースキャリーセルで再実装が必須。
- [pattern] CSS scroll-snap carousel でループを実装する際、先頭・末尾にクローンスライドを追加し、scrollend イベントで着地位置を検出してリアルスライドへ instant ジャンプする手法が有効（参考：Pietro テーマの Swiper.js `loop: true` と同等の効果）。
- [gotcha] スクロールキャリーセル内の画像ドラッグが div の drag ハンドラに割り込む場合、`-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` の組み合わせでネイティブドラッグを抑制し、スクロール優先度を確保する。
- [gotcha] Prestige の `slideshow-carousel` は CSS で非アクティブスライドを `position: absolute; visibility: hidden` で隠すため、peek（隣スライドのチラ見え）は構造的に不可能。このケースでは `scroll-carousel`（scroll-snap ベース）への切り替えが必要。
- [pattern] 無限ループを実装する際、最初のスライドを末尾に、最後のスライドを先頭に clone 配置し、scrollend でリアルスライドへ瞬時ジャンプさせるアプローチで、フレームワークなしでも視覚的に途切れない loop を実現可能。
- [gotcha] `scroll-carousel` 上の画像ドラッグで、ブラウザネイティブドラッグが drag ハンドラより優先実行されるため、`pointer-events: none` + `-webkit-user-drag: none` + `user-select: none` の 3 つを組み合わせて抑制する必要がある。
- [gotcha] Prestige の CSS `.slideshow__slide:not(.is-selected) { visibility: hidden }` により opacity フェード時の peek は構造的に不可。テーマ CSS 制約を最初に確認してから設計すること
- [pattern] スライド複製ループ：最終スライド clone を先頭、最初スライド clone を末尾に追加し、`is-initial` で初期位置固定、scrollend で `instant` ジャンプ。視覚的に切れ目なし
- [pattern] Prestige のような paid theme では既存セクション名を変更せず、機能追加は新規セクション追加で対応するのが正解
- [gotcha] Prestige の `slideshow-carousel` は非選択スライドを `position: absolute; visibility: hidden` で隠すため、peek は CSS 構造上不可能。`scroll-carousel`（scroll-snap）に切り替えが必須。
- [pattern] CSS scroll-snap のループ実装：最終・最初スライドをクローン追加、`scrollend` でクローン着地時にリアルスライドへ `instant` ジャンプ。視覚的に切れ目なし。
- [tip] スクロール時の画像ドラッグ選択を防ぐ：`-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` 組み合わせ。リンクスライドはバブルで機能維持。
- [gotcha] Prestige の `slideshow-carousel` は非選択スライドを `position: absolute; visibility: hidden` で隠すため peek は構造的に不可。`scroll-carousel`（scroll-snap ベース）への切り替えが必須。
- [pattern] スクロールカルーセルの infinite loop: 最終スライドの clone を先頭に、最初のスライドの clone を末尾に追加し、`scrollend` で実スライドへ瞬時ジャンプで視覚的に切れ目なし。
- [gotcha] img ネイティブドラッグを防ぐには `-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` で複合抑制。これなしだと scroll ハンドラより優先される。
- [tip] Shopify CLIセッション切れ時は `shopify auth login --store <store>.myshopify.com` または `--device-code` でセッション復旧可能
- [pattern] `shopify theme push --only layout/theme.liquid` で特定ファイルのみプッシュ可能。settings_data.json など不要な変更の混入を防ぐ
- [gotcha] Shopify CLI セッション切れ時、`shopify theme push` は `shopify auth login --store <store>` で再認証が必要。インタラクティブログインの場合はブラウザのコード入力も求められる
- [pattern] `settings_data.json` に変更がない場合、`shopify theme push --only <file>` で特定ファイルのみプッシュして不要な data.json 変更を回避
- [tip] Shopify CLI の認証が必要な操作は IDE ツール統合より、ターミナルで直接実行する方が確実（ブラウザ認証やコード入力が必要な場合）
- [pattern] Shopify Liquid のレスポンシブリンク対応：PC 用/モバイル用で別々の `<a>` 要素を用意し、`md:hidden`/`md-max:hidden` で表示制御すると、異なるリンク先でも保守性が高い
- [tip] Shopify テーマ push 前に `git diff config/settings_data.json` で意図しない設定変更がないか必ず確認してから実行
- [pattern] Shopify Liquidで異なる表示分岐する要素が異なるリンク先を必要とする場合、Tailwindクラス（`md-max:hidden` など）で分岐した各要素を別々の `<a>` タグでラップする実装パターン
- [gotcha] `shopify theme push` 前に `config/settings_data.json` の diff を確認し、意図しない自動生成変更を含めていないか警告する
- [gotcha] Shopify CLI実行時は事前にストアドメインを確認。複数ストア運用時は `shopify theme list` で現在のコンテキストを確認必須
- [pattern] Liquid条件付きレスポンシブ（`md-max:hidden` / `md:hidden`）でモバイル/PC版を分離し、異なるリンク先を指定可能
- [tip] プッシュ前に `git diff --name-only` で変更ファイルを確認し、settings_data.json の不意な変更を検出
## 2026-04-20 13:50 | teras-taya
- peek が出なかった根本原因:
- [gotcha] - コード: `DJCD-WNGJ`
- [correction] ストア間違えています。今のリポジトリを確認して。
## 2026-04-20 13:58 | P130
- [correction] を明示的にしてあなたがプッシュするリポジトリを間違えないようにするにはどうすればいい？
- 結論: ストアドメイン自体は公開情報なのでリスクは低いですが、`.envrc` に何を書くかで扱いが変わります。以下、実務上の注意点。
- [gotcha] 結論: ストアドメイン自体は公開情報なのでリスクは低いですが、`.envrc` に何を書くかで扱いが変わります。以下、実務上の注意点。
## 2026-04-24 22:20 | P130 [ai]
- [gotcha] shopify auth logout/login を毎回自動化するとCLIキャッシュが壊れて遅くなる。認証切り替えより対象store固定と検証を優先すること。
- [pattern] Shopifyリポジトリの間違えプッシュ防止：direnv+SHOPIFY_FLAG_STORE固定 → pre-pushフック検証 → シェル関数確認の多層防御パターン。
- [tip] .envrc は .gitignore で除外し .envrc.example をコミット。store情報漏洩防止とチーム内柔軟性の両立。
- [gotcha] Shopify複数ストア環境で `shopify auth logout/login` を毎回手動実行するのは事故リスク。direnv + SHOPIFY_FLAG_STORE 固定 + pre-push フックで対象ストア認証を自動検証する。
- [pattern] .envrc は公開情報（store URL）のみコミット。トークン類は .envrc.local に分離して .gitignore + pre-commit フックで検出。
- [tip] Shopify トークン漏洩防止: pre-commit フックで `shpat_|shpca_|shppa_|shptka_` パターンを検出。GitHub push protection + gitleaks も併用。
- [pattern] Remote agentは別コンテキストで実行されるため、メイン会話のコンテキストを消費しない。結果テキストの返却分だけが消費される
- [pattern] headlessパターンで結果をファイル出力・通知のみにすれば、会話コンテキストへの影響をゼロにできる
- [tip] remote-control/RemoteTrigger/headless実行で動作が異なるため、コンテキスト圧迫回避が目的なら headless（別プロセス）を優先
## 2026-04-20 14:00 | ANIECA_ver02
- 🛍️ Shopify Theme | ... | ⚠️ SHOPIFY_FLAG_STORE未設定
- [gotcha] 🛍️ Shopify Theme | ... | ⚠️ SHOPIFY_FLAG_STORE未設定

## 2026-04-20 14:00 | ANIECA_ver02 [ai]
- [pattern] Store URL を `.envrc` で固定し SHOPIFY_FLAG_STORE 環境変数で CLI を自動切替。毎回 logout/login を手動で打つより pre-push hook で認証検証する方が事故耐性高。
- [gotcha] `.envrc` に Shopify token を書くと GitHub scanning 対象になり流出リスク。store URL のみコミット、token は `.envrc.local` で分離管理。
- [tip] Shopify token（shpat_, shptka_ など）検出の pre-commit フックで二重防止。gitleaks や GitHub push protection も併用推奨。

## 2026-04-21 13:21 | Beauty-Select
- > 注意: Shopify の Customer Segment API は比較的新しい。セグメント条件（`customer_tags CONTAINS 'userrank-gold'` 等）でディスカウントを制限できるか動作確認が必要。
- [correction] 4. **ディスカウントの割引率** ― ランクごとに異なる？
- 調査完了。Shopify APIで判明した重要な事実を整理します。
## 2026-04-21 13:25 | Beauty-Select [ai]
- [pattern] Shopifyで月次ランク更新やディスカウント発行などの定期バッチ処理が必要な場合、GitHub Actions + Admin GraphQL API + Bulk Operations APIの組み合わせが標準。Shopify単体では実装不可。
- [gotcha] 顧客スケール（数百人 vs 数万人）でAPI選択が大きく変わる。実装前にスケール規模を確認しないと工数見積もりが2倍以上ズレる可能性がある。
- [gotcha] Customer Segment APIなど比較的新しいShopify APIでセグメント条件（タグ絞り込み等）を使う場合、ドキュメント通りに動作するか実装前のPoC確認が必須。
- [gotcha] Shopifyの`amount_spent`は全期間のみで過去N年指定不可。Admin APIで注文を日付フィルタして集計するスクリプトが必須。
- [pattern] Liquidの`customer.tags`と`date`フィルタで当月コード（2026APR等）を動的生成できる。ランク別表示に有効。
- [pattern] Shopifyディスカウント+セグメントAPIはドキュメント例がユースケースと完全一致。標準機能で実装可、開発見通しが立つ。
- [gotcha] Shopify Admin GraphQL の `amount_spent` フィルタは「全期間合計のみ」で過去1年指定不可 → 期間ベースの顧客ランク計算は GitHub Actions スクリプト必須
- [pattern] `account.liquid` はセクションシステム非対応のため、複雑なUIはスニペット化+`{% render %}` 1行追加が最適（セクション化移行はコスト > メリット）
- [tip] Liquid の日付フィルタ `'now' | date: '%Y%b' | upcase` でコード名「2026MAY」を自動生成可能
- [gotcha] Shopify のセグメント query 言語の `amount_spent` は全期間合計のみで「過去1年」指定不可。「過去1年購入額」ベースのランク計算は Admin API で注文を日付フィルタして集計するスクリプトが必須。
- [pattern] `account.liquid` はセクションシステム非対応。スニペット + `{% render %}` で実装し、テーマ設定を `settings_schema.json` で UI 化すると、月次のコード更新を非開発者が管理画面で対応可能。
- [tip] Shopify ディスカウント API の `segmentCreate` + `discountCodeBasicCreate` で顧客セグメント指定のコード発行が標準機能。セグメント制限も API から自動制御でき、後付けルール不要。
## 2026-04-21 14:32 | Pinup-Closet_ver01
- ### 🔴 Critical Issues
- [gotcha] HTML IDにスペースは無効で、`getElementById` はスペース区切りの複合IDにマッチしない。devtoolsで確認した値は `class="fsb sr summary"` というクラス名を誤読した可能性が高く、Strategy 1 は全ページで必ず失敗する。
- ⚠️ Needs work — Critical 2件、Important 4件を対応してからマージ推奨。
- 完了: - [pattern] ロケール文字列・CSSクラス・IDの削除・変更前に全プロジェクト検索で他テンプレートへの影響を確認。複数箇所に依存していないか確認してからマージ。
- [pattern] 完了しました。
## 2026-04-21 14:32 | Pinup-Closet_ver01 [ai]
- [gotcha] HTML IDはスペース不可。`getElementById` で見つからない場合、devtoolsで見えるのはクラス名の可能性がある。セレクターなら `.class1.class2` または `[class*="keyword"]` を使用。
- [gotcha] DOM操作で属性をセット後にエラーが発生すると、属性だけ残って状態が不整合になる。`setAttribute` は操作成功後に実行し、try-catchで初期状態に戻す。
- [pattern] ロケール文字列・CSSクラス・IDの削除・変更前に全プロジェクト検索で他テンプレートへの影響を確認。複数箇所に依存していないか確認してからマージ。
- [gotcha] HTML id 属性にスペースを含む値は無効。`getElementById("fsb sr summary")` は常に null。DevTools の `class="fsb sr summary"` を ID と誤認しやすい罠。
- [pattern] DOM修正時、修正成功フラグ（`data-*` 属性等）は操作後に付与する。操作失敗時にフラグだけ残るとリトライが機能しなくなる。
- [gotcha] Shopify Dawn テーマの既存クラス（`title-wrapper-with-link` 等）をリネームすると定義済みスタイルが失われる。リネーム不要なら並存させるべき。

## Recurring Patterns (updated 2026-04-24)
- [general/shopify] Python script delegation — seen 38 times
- [cross] token budget / compress — seen 35 times
- [general/shopify] commit format — seen 27 times
- [cross] Shopify Liquid — seen 26 times
- [general/shopify] dotfiles sync — seen 25 times
- [general/shopify] error handling — seen 19 times
- [general] git pull / ff-only — seen 5 times
- [general] SessionStart hook — seen 3 times
- [general/shopify-app] webhook — seen 3 times
## 2026-04-24 11:56 | mimc-mailmagazine

## 2026-04-24 22:20 | P130 [ai]

## 2026-04-24 22:25 | dotfiles

## 2026-04-24 22:25 | dotfiles

## 2026-04-24 22:25 | dotfiles [ai]

## 2026-04-24 22:36 | dotfiles

## 2026-04-24 22:36 | dotfiles [ai]

## 2026-04-24 22:41 | dotfiles
- 完了: 修正完了。886行追加（ローカルにあった未同期の学習ログをdotfilesへマージ）しました。

## 2026-04-24 22:41 | dotfiles [ai]
- [gotcha] セットアップ後の symlink は自動修復がないと漂流する。`~/.claude/learnings/`, `~/.claude/tools/` が実ディレクトリに変化し、SessionStart の stop hook が誤ったパスに書いて GitHub sync がずれていく。
- [pattern] 複数の診断・修復フロー（セッション開始時、手動診断、setup検査）は単一 Python スクリプトで複数モード提供する設計。20+ 回の bash 連打が `python3 ~/.claude/tools/dotfiles-doctor.py [--hook|--verbose|--check]` の1呼び出しに統一できる。
- [tip] 自動修復スクリプトは修復成功時は silent、問題時だけ systemMessage で通知すると UX がよい。ユーザーが「修復された」ことを認識できるが、問題なければノイズが出ない。

## 2026-04-25 08:30 | dotfiles

## 2026-04-25 08:30 | dotfiles [ai]
- [gotcha] dotfiles の symlink が断裂していても、ローカルに実ディレクトリがあれば動作は続く。GitHub 同期だけが止まり気づきにくい → SessionStart の自動ヘルスチェック必須
- [pattern] 診断スクリプト（dotfiles-doctor.py）を SessionStart に組み込むことで、別PC での初回起動時も symlink が自動修復される → 設定共有の信頼性向上
- [tip] 削除時は即 rm でなく ~/.trash に退避してから再作成することで、誤った破棄から復旧可能にする → CLAUDE.md の block-rm.sh と同じ安全性パターン

## 2026-04-25 09:05 | dotfiles

## 2026-04-25 09:05 | dotfiles [ai]
- [gotcha] Symlink が実ディレクトリに化けると、Stop hook が沈黙破壊される（正しいパスに書き込めず、セッション学習がGitHubに届かないまま差分が溜まる）
- [pattern] dotfiles-doctor.py のような一元化診断スクリプトを SessionStart hook に組込むことで、複数PC間の初期化ズレが自動修復される仕組みが実現できる
- [tip] Symlink 修復時は `rm` ではなく `~/.trash` に退避してブロックリスト準拠を確保すると、安全かつ repeatable な修復になる

## 2026-04-25 09:18 | dotfiles

## 2026-04-25 09:18 | dotfiles [ai]
- [gotcha] symlink が実ディレクトリに置き換わると、セッション終了時の learnings 保存が別ファイルに行われ、別PC への同期が無声で止まる。SessionStart時に自動修復する仕組み必須
- [pattern] dotfiles同期は SessionStart で pull、セッション終了時に save-learnings → commit → pull --rebase → push で別PC即時伝播と夜間バッチ整理を両立
- [tip] CLAUDE.md が参照する複数の symlink（tools/, learnings/, memory/）を一括チェックする診断スクリプトで、問題分析時のコンテクスト消費が20回の個別Bash → 1回の統合呼び出しに圧縮される

## 2026-04-25 09:27 | dotfiles

## 2026-04-25 09:27 | dotfiles [ai]
- [gotcha] dotfiles symlink は setup 直後に壊れていることに気づきにくい。SessionStart で自動修復を仕込まないと、別PCやリセット後に同期がこっそり止まる
- [pattern] 診断ツールを最初から用意する — 小さな Bash/ls/diff 20回の連打より、1本の Python スクリプト（doctor.py）が回答を圧縮する
- [tip] 破壊操作は `~/.trash/` に退避してから実行すると、誤削除時の復旧が容易。block-rm.sh 準拠なら自動的に保護される

## 2026-04-25 10:18 | dotfiles
- [gotcha] ### 🔴 1. Stop フックの実行順が逆 → learnings が常に1セッション遅れて push される
- [correction] いままでの作業内容を見直して、ブラッシュアップできるところはありますか？
- [gotcha] 注意: メタフィールドが未設定の商品では何も表示されません。`custom.category` も未設定の場合はカテゴリーテキストが省略されます。
- [pattern] Prestige のセクション余白は `--section-vertical-spacing-override` カスタムプロパティで制御。直接 margin/padding 指定ではなくこのプロパティを上書きする。
- [gotcha] 複数フィーチャーが混在するブランチから特定の修正のみ main に反映する場合は cherry-pick を使用。全マージすると無関係な機能が含まれるリスク。
- [tip] Prestige ではセクション内パディングとセクション間ギャップが異なるプロパティで制御される（`--section-vertical-spacing-override` vs `section-stack-gap`）。余白調整時は両方確認が必要。
## 2026-04-21 13:21 | Beauty-Select
- [gotcha] > 注意: Shopify の Customer Segment API は比較的新しい。セグメント条件（`customer_tags CONTAINS 'userrank-gold'` 等）でディスカウントを制限できるか動作確認が必要。
## 2026-04-21 13:25 | Beauty-Select [ai]
## 2026-04-21 14:32 | Pinup-Closet_ver01
- [gotcha] ⚠️ Needs work — Critical 2件、Important 4件を対応してからマージ推奨。
## 2026-04-21 14:32 | Pinup-Closet_ver01 [ai]

## Recurring Patterns (updated 2026-04-26)
- [shopify] Liquid template / metafield usage — seen 33+ times
- [general] Python script delegation (preprocess→Claude→postprocess) — seen 72 times
- [general] git commit / push workflows — seen 56 times
- [shopify] CSS selector specificity / style leak — seen 51 times
- [shopify] JavaScript event handler / delegation — seen 35 times
- [general] SessionStart / Stop hook automation — seen 24 times
- [shopify] Swiper slider loop configuration — seen 21 times
- [shopify] Metafield list type output — seen 19 times
- [shopify] img_url deprecated → image_url — seen 5 times
- [shopify/ecforce] Platform differences (Liquid syntax) — seen 112 times
- [security] API token single-display safety — seen 5 times


## 2026-04-25 | dotfiles [ai]
- [gotcha] ### 🔴 Stop フックの実行順が逆 → learnings が常に1セッション遅れて push される


## 2026-04-22 11:18 | mimc.co.jp-mailmagazine
- 完了: 修正しました。変更内容：

## 2026-04-22 11:18 | mimc.co.jp-mailmagazine [ai]
- [pattern] メール HTML は複雑なテーブルレイアウトより `<p>` タグのシンプル縦並びが、メールクライアント互換性と修正効率の面で優れている。
- [tip] PDF 仕様書とスクリーンショットを並べ比較すると、期間表記・特典表示・画像配置の細かい違いが効率よく発見でき、実装前検証として有効。
- [pattern] キャンペーンボックス内のプレゼント表示は、複数商品サムネイル行より全幅画像 1 枚の方が、訴求力と収まりが良い。

## 2026-04-22 11:27 | mimc.co.jp-mailmagazine

## 2026-04-22 11:27 | mimc.co.jp-mailmagazine
- [gotcha] - [gotcha] CAMPAIGNボックス内の要素構成（画像の配置位置や数）はスクリーンショット確認なしに決定してはいけない。ユーザーのビジュアルフィードバックで修正

## 2026-04-22 11:27 | mimc.co.jp-mailmagazine [ai]
- [pattern] メールHTML の縦方向余白は em、横方向は px で統一。相対単位がメールクライアント対応性に優れている
- [gotcha] CAMPAIGNボックス内の要素構成（画像の配置位置や数）はスクリーンショット確認なしに決定してはいけない。ユーザーのビジュアルフィードバックで修正
- [pattern] 複数ファイルの一括置換（px→em 変換など）が必要な場合、Pythonスクリプトで自動化して効率化

## 2026-04-22 11:47 | mimc.co.jp-mailmagazine

## 2026-04-22 11:47 | mimc.co.jp-mailmagazine [ai]
- [pattern] メールマガジンのプレゼント表示は複数商品のサムネイル行ではなく、横幅いっぱいの1枚画像（`0424_present.jpg`）が正解パターン
- [pattern] メール HTML の縦方向余白（top/bottom）はすべて em で統一；横方向は px のまま。Pythonスクリプトで一括変換可能
- [pattern] 右向き三角「▶」は HTMLエンティティではなく UTF-8 文字を直書き（`▶ 詳しくはこちら`）

## 2026-04-22 11:49 | mimc.co.jp-mailmagazine

## 2026-04-22 11:49 | mimc.co.jp-mailmagazine [ai]
- [pattern] メールマガジン制作時は縦方向の余白（margin-top/bottom）をemで統一し、横方向はpxで統一。メールクライアント環境での表示安定性を確保。
- [tip] メール環境での矢印記号は文字直書き`▶`より数値参照`&#9658;`が安全。Outlookを含めた広い互換性が必要な場合は数値参照推奨。
- [pattern] メールマガジンの期間・特典表示はテーブル要素ではなくp要素の段落で実装。テーブル構造はメールクライアント依存で崩れやすい。

## 2026-04-22 11:58 | mimc.co.jp-mailmagazine

## 2026-04-22 11:58 | mimc.co.jp-mailmagazine [ai]
- [correction] メールHTMLの右向き三角は▶直書きではなく`&#9658;`（数値参照）で実装 — 環境依存リスク対策
- [pattern] メルマガHTMLの縦方向余白（padding/margin-top/bottom）はすべてemで統一すると、フォントサイズ基準で相対的に保守性向上
- [pattern] 複数商品表示は画像と説明を左右交互で縦並びレイアウトすると視覚的な動きが出て効果的

## 2026-04-22 12:11 | mimc.co.jp-mailmagazine
- - クーポンBOX（コード＋注意事項）→ お買い物はこちら
- - クーポンBOX（コード＋お買い物はこちらボタン）→ 注意事項

## 2026-04-27 13:18 | mimc.co.jp-mailmagazine

## 2026-04-27 13:18 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メールHTMLで右向き三角を直書き（`▶`）すると環境依存リスク。`&#9658;` HTMLエンティティで統一すべき
- [pattern] Pythonで縦方向余白を一括変換：正規表現で縦方向`px`→`em`に、横方向は変更なし
- [tip] メール設定テンプレートはYAMLより`tomllib`（Python 3.13標準）TOML形式が簡潔で追加パッケージ不要

## 2026-04-27 13:23 | P130 [ai]
- [gotcha] `git push` 前にリモート分岐の大きなズレを検出したら即座に `git fetch` + rebase/merge 判断が必須。先行/遅延が大きい状態での push は拒否される。
- [pattern] dotfiles や リモート関連の git 操作は `status` → `diff` → 分岐確認を順序固定で実施。untracked や分岐状態の見落とし防止。
- [gotcha] スキル実行で sync コマンド提示後、リモート分岐が大きい例外系は手動確認が必要。スキルは基本フローのみ、conflict/fetch失敗時は自動実行不可。

## 2026-04-27 13:25 | P130
- [pattern] ローカル6コミット（セッション学びログ）vs リモート45コミット（nightly-monitor等）の分岐です。両側とも別ファイルへの書き込みなので `git pull --rebase` で解消できます。実行してよいですか？
