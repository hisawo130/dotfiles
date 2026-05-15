# General Learnings

## 2026-04-28 | dotfiles

- [gotcha] セッション起動時の自動pullは未コミット変更があるとコンフリクト。`--ff-only`を併用し、失敗時は警告して停止する。
- [pattern] セッション開始フック実装前に、既存フック（pull-dotfiles.sh等）との重複を確認し、統一・整理が必須。
- [pattern] 複数PC運用では起動時に `git pull --ff-only` を自動実行。SessionStart フックで古い状態での作業開始を防ぐ。
- [pattern] 大量ファイル処理のバッチ処理は、クライアント前処理（Python要約生成）→Claude軽量処理（JSON digest受け取り）→後処理スクリプト（ファイル書込）の3段階に分割するとトークン削減と再現性が両立
- [gotcha] 定期実行バッチ（cron）では「データ集計・パトロール・パターンマッチ」などPythonで完結できる処理をClaudeに通さない設計が必須。生ファイル一括読み込みはスケールしない
- [tip] JSON digest形式での前後処理分離は、Claude側プロンプトも簡潔に保ち「判断・観察」のみに専念させるため、定期実行タスクには特に有効
- [gotcha] プロンプト最適化だけではトークン削減の限界あり、Claudeの作業範囲をアーキテクチャレベルで縮小する方が効果的
- [pattern] 大量ファイル読み込みはPython前処理で要約化し、ClaudeはJSON I/Oのみに限定。トークン消費を90%削減できる。
- [gotcha] cronの一元化: 複数PCでローカル登録は管理コスト高。GitHub Actionsで一元化すれば、PCのオン/オフに左右されず確実に実行可能だが、APIキー・CI設定が必要。
- [gotcha] GitHubActions YAMLで複数行文字列（ヒアドキュメント）を埋め込むとパーサー衝突。プロンプト生成は別Pythonスクリプトに切り出す
- [pattern] cron スケジュール `0 3 * * 1-5`（月〜金AM3:00のみ）で5h/7dレート制限を最適化 — AM8:00/月曜AM9:00開始時に消費を最小化できる。
- [gotcha] GitHub ActionsでAnthropicを使う場合、リポジトリSecretsに `ANTHROPIC_API_KEY` を登録しないと実行時に失敗する。ローカルのシェル変数との区別が必要。
- [pattern] Shopify Dev MCPは認証不要で即座に使用可。Admin MCPはアクセストークン・ストアURLが環境変数必須。まずDev MCPから開始する方が段階的で効率的。
- [gotcha] dotfiles更新時は既存のrebase等状態を先に完了させてから新しい変更をコミット。git状態確認→変更待避→rebase完了→追加コミット の順序が重要。
- [pattern] MCPやpermissions等の配列設定は全置換せず、既存内容を保持したまま新要素を統合・追加するapproach。
- [gotcha] セットアップスクリプトで作成したシンボリックリンクは、git の push/clone 後や同期操作で実ディレクトリに置き換わることがある。`ls -la ~/.claude/learnings` で定期確認が必要
- [pattern] auto-memory で複数ディレクトリ間の同期が必要な場合、symlink より hardlink（inode同一）が robust。memory/ で実績あり
- [gotcha] 夜間バッチで自動書き込みされるファイルが symlink 経由の場合、symlink の壊れを検出できない。バッチの最後に「書き込み先が期待通りか」を検証する guard clause が必要
- [gotcha] symlink が実ディレクトリに変わると Stop hook が沈黙に失敗し、セッション学習が dotfiles に入らず複数 PC で同期されない。symlink を定期検証すること
- [pattern] dotfiles symlink + GitHub → セッション終了 Stop hook で自動 commit/push → 次セッション開始時 pull で即時反映。別PC間同期はセッション境界で完結
- [gotcha] セットアップ後の symlink は自動修復がないと漂流する。`~/.claude/learnings/`, `~/.claude/tools/` が実ディレクトリに変化し、SessionStart の stop hook が誤ったパスに書いて GitHub sync がずれていく。
- [pattern] 複数の診断・修復フロー（セッション開始時、手動診断、setup検査）は単一 Python スクリプトで複数モード提供する設計。20+ 回の bash 連打が `python3 ~/.claude/tools/dotfiles-doctor.py [--hook|--verbose|--check]` の1呼び出しに統一できる。
- [tip] 自動修復スクリプトは修復成功時は silent、問題時だけ systemMessage で通知すると UX がよい。ユーザーが「修復された」ことを認識できるが、問題なければノイズが出ない。

- [open] 1. Stop フックでlearningsのタグ品質チェック — セッション終了時に `[open]` が残っている項目をサマリー表示（未解決の課題を見逃さない）
- [gotcha] ### 🔴 1. Stop フックの実行順が逆 → learnings が常に1セッション遅れて push される
- [gotcha] 注意: メタフィールドが未設定の商品では何も表示されません。`custom.category` も未設定の場合はカテゴリーテキストが省略されます。
- [pattern] Prestige のセクション余白は `--section-vertical-spacing-override` カスタムプロパティで制御。直接 margin/padding 指定ではなくこのプロパティを上書きする。
- [gotcha] 複数フィーチャーが混在するブランチから特定の修正のみ main に反映する場合は cherry-pick を使用。全マージすると無関係な機能が含まれるリスク。
- [tip] Prestige ではセクション内パディングとセクション間ギャップが異なるプロパティで制御される（`--section-vertical-spacing-override` vs `section-stack-gap`）。余白調整時は両方確認が必要。
- [gotcha] Symlink破損するとセッション学習がGitHubに届かなくなる。Stop hookが正しいパスに書き込めず、別PCで反映されない。SessionStart時の自動チェック機構が必須。
- [pattern] 複数の小さな診断Bash/ls/diffコマンド（20回超）は1つのPython統合ツール（`dotfiles-doctor.py`）で置き換え可能。トラブルシューティングのコンテクスト消費が激減する。
- [tip] 別PC間の設定同期では、symlink有効性の定期検証習慣が重要。SessionStart自動チェック＋手動確認用コマンド両方があると早期発見できる。

- [pattern] APIキー管理は3つのケースに分類：①dotfiles同期（Git運用、キー不要）②GitHub Actions（Secrets使用）③interactive CLI（OAuth認証）で、状況に応じて使い分け
- [pattern] `claude auth login` でブラウザOAuth認証すれば、APIキー手動入力ゼロで setup.sh を完結可能
- [pattern] macOS Keychain に APIキー保存 → iCloud自動同期で、新Macのセットアップ時に再入力不要
- [gotcha] スキル開発：作者の自己再読には bias が避けられない。必ずバイアスフリーなサブエージェントで実行テストする。修正は1イテレーション1テーマに絞らないと「何が効いたか」が潰れる。
## 2026-04-28 | mimc-mailmagazine
- [open] 要確認: 各商品画像は `0414_01.jpg` 〜 `0414_05.jpg` としています。実際にアップロードされる画像ファイル名と異なる場合は差し替えをお願いします。
- [open] - No.4 ナチュラルトリートメントアップチャージ: SKUの対応が不確かで要確認
- [correction] 以下のコードを参考にして修正してください

- [pattern] メールマガジンHTML新規作成時は既存テンプレートと関連配信HTML（前回分など）を確認して構造と画像パスを把握してから実装する
- [gotcha] 画像ファイル名を仮置きする場合、実装後に実際のアップロード名と照合して差し替えが必要
- [gotcha] メールHTML複数版で同じ商品SKUが異なるalt文や画像ファイルに紐づくことがある。流用時は「SKUが一致」だけでなく、画像の中身と商品説明の整合性を確認してから採用判定する
- [pattern] 既存ファイルから画像を探す際、grep で全ファイルから対象SKUをマッピング検索し、複数ファイル間の一貫性を確認してから流用可否を判断
- [tip] alt属性が異なるバージョン間では、SKUと商品URLの紐付けで正規化を図る（alt文字列だけに頼らない）
- [gotcha] 複数メルマガ間でSKU・商品対応が不統一。画像流用は全件検索後にユーザー確認 → 実装の順でないと修正コストが増える
- [gotcha] メールの商品ランキング作成時、複数メール間でSKU対応が異なる可能性がある。既存メールから画像流用する際は画像の中身を確認してから置き換えること
- [pattern] メールクライアント互換性を考慮したランキング番号ラベルは `<span style="font-size: 11px; border: 1px solid #333; padding: 4px 8px; display: inline-block; margin-bottom: 0.4em; line-height: 1; vertical-align: bottom;">No.1</span>` で実装
- [pattern] メルマガHTML作成時は、同時期や関連メールから画像・スタイルを流用してアセット作成を最小化。流用前に商品情報との整合性をマッピングで確認。
- [correction] HTMLメールのラベル表示など、PDFで指定された視覚的フォーマット（font-size、border、padding等）は厳密に適用。メールクライアント互換性に直結。
- [gotcha] HTMLメール実装は視覚的デザイン確認が必須。ラベル位置・ボタンUIなどPDFと一致していることを視覚検証してから実装完了と判断する
- [pattern] 新規メール制作時は複数の既存テンプレート（260401, 260410など）から構造・画像パスの参考源を先に確認してからコーディング開始
- [pattern] HTML メール修正は見た目確認だけでなく、PDF仕様書の配置（画像とタイトル間）・スタイル詳細（border/padding）・UIを厳密に確認してから実装する
- [pattern] 複数変更を一度に加えず小分けにして各段階でユーザー確認を挟む（後から「変更前に戻して」は修正リスク増加）
- [correction] PDFデザイン参考時、ラベル表示位置・ボタンUI等の細部仕様を最初から完全に理解してからコード作成開始する。視覚位置のズレや形状違いは修正ループを増やす。
- [pattern] メールHTMLのUI要素（ラベル、ボタン）は、メールクライアント互換性を考慮した実装パターンを参考コード例として確保し、デザイン↔実装ギャップを未然に防ぐ。
- [gotcha] 同じSKUが異なるメール間で異なる商品説明を持つことがある。画像流用時は必ず内容確認が必要（alt テキストと実際の商品が一致しているか検証）。
- [tip] メール HTML のラベル・ボタンUIはインラインスタイルで細かく指定（`border`, `padding`, `display: inline-block`）。メールクライアント対応を前提に PDF デザインと正確に合わせる。

- [pattern] メルマガ HTML コーディング時は「要確認・差し替え画像」を構造化リスト化し、新規/流用・パス形式を明示してユーザー確認を取る → 修正ラウンドを削減できる
- [gotcha] メール HTML のファイルパスに `__`（ダブルアンダースコア）や特殊記号があるとメールクライアント対応で崩れるリスク → パス確認は必須チェック項目
- [correction] メルマガ HTML 完成後は「ブラウザプレビュー + メールクライアント実表示確認」が必須（CLAUDE.md に明記）だが、タスク報告時に確認状況を明示すること
- [gotcha] メルマガHTMLのコーディングリクエスト時、PDFファイル指定があいまいな場合は実装を始める前に必ずファイル存在確認してから進める
- [pattern] メルマガHTML完成後、差し替えが必要な素材（KV画像、RECOMMEND画像、URL等）をテーブル形式で一覧化すると、ユーザーの確認・差し替え作業が効率化される
- [tip] 前の配信素材を流用する場合は流用理由を明記しておくと、ユーザーが差し替え判断しやすい
- [pattern] メルマガHTML作成時は直近の成功ファイルをテンプレートベースとして参照・流用し、セクション構成・スタイル・リンク構造を継承する
- [gotcha] 新規配信分のメルマガは画像ファイルの差し替えが必須確認項目。ダブルアンダースコアパス（`img_top__st.jpg`）はメールクライアント対応時に注意
- [pattern] テンプレート流用時は UTM パラメータを配信日（YYMMDD）に一律更新することで追跡精度を確保し、置換処理は機械的に実行可能
- [gotcha] メールHTMLのURL・プロダクトコードは推測値を避け、既存テンプレートで確認済みの値を引用する
- [tip] ファイル参照時に「見つかりません」と報告する際は、候補ファイル名を複数挙げるとユーザーの確認効率が上がる

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

## 2026-04-14 10:23 | pietro-onlineshop_dev
- [gotcha] コード上 `input.discount.discountClasses` に `SHIPPING` が含まれないと即 `{operations: []}` を返す設計です。アプリを削除・再作成したことで既存のディスカウントも消えています。

- [pattern] Shopifyアプリデプロイ前に、ブランチ先行状態とマージ予定を確認し、リリース範囲を明確化する
- [gotcha] 本番デプロイ時に`shopify.app.<config>.toml`で環境を指定するステップを忘れやすい—手順チェックリストに含める
- [tip] 複数ブランチが並行している場合、デプロイ前に全ブランチのコミット差分を`git log main..develop`で可視化してから確認質問を出すと齟齬が減る
- [pattern] デプロイ前の流れ：状態整理（各ブランチのコミット差分）→ マージ計画の確認 → 実行手順の明示 → 明示的な「進めてください」許可待ち
- [pattern] Shopify アプリのデプロイ手順がドキュメント化されていれば、デプロイ前に参照して手順を確認・チェックできる。
- [tip] 本番デプロイ後、本番アプリダッシュボード URL と設定ファイルの client_id を照合することで、デプロイの正確性を検証できる。
- [gotcha] 本番デプロイ前に含めるコミット範囲とマージ戦略を複数回確認してからマージを進める
- [gotcha] 「アプリ削除」と「アンインストール」は対応が異なるため、事前に区別して確認する必要がある
- [pattern] デプロイ手順書に確認チェックリスト（含めるコミット、設定ファイル、client_id 検証）を組み込む
- [gotcha] Shopifyアプリが削除・再作成されたら`client_id`が変わる。`shopify app config link`で新アプリにリンク直しが必須
- [pattern] アプリ連携変更時は `shopify app config link --config <toml>` でリンク直し。Partner Dashboard のアプリ一覧から選択すると client_id 自動更新。
- [tip] Partner Dashboardでのアプリ削除とストア管理画面でのアンインストールは別。前者は新規アプリ作成、後者は再インストール可能
- [tip] リポジトリから削除済みのextensionをデプロイする際の警告は、アプリを再作成している場合はユーザーデータ既消のため`Yes`で進めて問題ない
- [tip] `shopify app deploy`は対話操作が必要なため、自動化できず手動ターミナル実行が必須
- [gotcha] アプリ削除によりDiscount設定も消滅 → Function は管理画面でDiscount再作成まで動作しない（`input.discount.discountClasses`が空）
- [gotcha] FunctionコードがFunction ハンドラで割引クラスをチェックしており、割引未作成＝Function未動作となる隠れた依存関係 — デプロイ後の動作確認時に注意
- [pattern] 複雑な送料判定ロジック（金額帯×地域×温度帯）は最大値（¥11,000以上）から始めるのが検証効率が高い
- [tip] Shopify Function デプロイ後に機能が動作しない場合、Function の入力条件（ディスカウント存在確認など）が満たされているか先に確認する。Function は前提データなしでは動作しない。
- [gotcha] Shopify アプリを Partner Dashboard で削除・再作成すると、割引ディスカウント等のリソースデータが消える。Function は Deploy されても入力データがないため動作しない。GraphiQL で functionId と `discount.discountClasses` を確認して診断する。
- [pattern] Shopify アプリデプロイ後の確認手順は、Deploy 成功 → Install app（既インストール時は自動適用） → カート動作確認（Function の入力データ含む）の順。
- [tip] 割引が機能しない場合、まずGraphQL APIで installed_functions を確認してFunction正常性を診断してからコード疑いに進む
- [pattern] Shopify アプリ本番デプロイは config link（client_id 同期）→ コミット → develop/main マージ → deploy の順序で実行する。
- [gotcha] Shopify アプリを Partner Dashboard で削除した場合、新しい client_id が生成される。設定ファイルを `shopify app config link` で再紐づけしないとデプロイ失敗。
- [pattern] デプロイ前に main と develop の先行状況を確認し、どのコミットをリリースするか明確にしておくと、ロールバック判断やミス防止が容易になる。
- [tip] Shopify アプリの config link は対話操作が必須のため、自動化できない。ユーザーに明確に手順を指示し、完了後に確認を取ることが重要。
- [gotcha] Shopifyアプリを削除・再作成すると client_id が変わる。デプロイ前に `shopify app config link` で新アプリに紐づけ直して client_id を更新する必要がある。
- [pattern] `shopify auth login` や `shopify app deploy` など対話操作が必要なコマンドはClaude Codeから実行できない。ユーザーにターミナルで直接実行するよう指示する。
- [tip] 本番デプロイ前に develop と main の差分を列挙し（コミット数・内容），リリース範囲を明示的に確認して認識を合わせる。
- [gotcha] Liquid の `!= blank` は JSON 文字列 `"[]"` を空でなく判定。メタフィールド型を Shopify 管理画面で確認し、必要に応じて明示的な空文字列チェックを実装する
- [pattern] 非同期初期化タイムアウト時はコンソール警告ではなく、ユーザーフィードバック（トースト等）を必ず追加してサイレント失敗を防ぐ
- [gotcha] `stopImmediatePropagation()` は同一ノード上の後続リスナーのみ抑制。異なるノード（`body` vs `document`）のリスナーは影響しない
- [gotcha] `pointer-events: none`はアクセシビリティ問題（テキスト選択不可）。代わりに明示的なホバーリセット（cursor + inherit）を使う。
- [gotcha] インタラクティブな `<span>` には `role="button"` 、`aria-label` 、Enter/Space キーハンドラが必須。キーボード操作不可だとスクリーンリーダー環境で機能しない
- [pattern] ポーリング/初期化待ちのタイムアウトはコンソール警告だけでは silent failure。ユーザー向けのトースト/アラートで失敗を即座に通知し、リトライループを防ぐ。
- [pattern] 非同期初期化のポーリングはフラグ（`isPolling...`）＋最大待機時間（5000ms）で明示的に多重実行防止＆タイムアウト処理を実装。
- [gotcha] HTML要素タイプ変更時（`div` → `span` など）はCSS副作用の再検査必須（フォント継承、`line-height`などの表示崩れ）
- [correction] `<span role="button">` はキーボースアクセス対応が必須（Enter/Space handler + aria-label）。Gemini review で指摘されたが未実装状態。
- [pattern] ポーリング実装では、再入場防止フラグ + maxWait + インターバル 100ms の組み合わせが堅牢。5秒タイムアウトは実用的な目安。
## 2026-04-20 13:58 | teras-taya [ai]
- [gotcha] Shopifyの `complementary_products` メタフィールドに当該商品自身が含まれる場合がある。ループ内で `product.id` との重複チェックでスキップ必須。
- [pattern] Shopify theme で `settings_data.json` は自動同期により変更される。PR作成時は事前に確認し、必要に応じてマージ時に `main` と同期させる手順を用意。
- [tip] メタフィールドデータをテンプレートで使う前に、バリデーション・フィルタリングステップを入れるとデータ品質の問題に強くなる。
- [pattern] peek 機能は scroll-carousel（スクロール型）で実装可能。opacity フェード型は非表示スライド完全に隠すため不適切
- [tip] サードパーティテーマの警告（`custom.overlay` など）は既存グループ名で問題なし。Prestige の命名規則を尊重してスキーマ追加
- [tip] 有料テーマ使用時は既存スライド実装の CSS 設計を最初に調査してから対応方針を決める。制約を理解することで最適な解決策を判断できる。
- [gotcha] Prestige の `slideshow-carousel` は非アクティブスライドを `position: absolute; visibility: hidden` で隠すため peek（隣スライドのチラ見え）は構造的に不可能 → `scroll-carousel` + CSS scroll-snap への切り替えが必須
- [pattern] scroll-carousel で loop を実現するには最終スライドの clone を先頭に、最初のスライドの clone を末尾に追加し、`scrollend` イベントでクローン着地時にリアルスライドへ `instant` ジャンプ
- [gotcha] `<img>` 要素のブラウザネイティブドラッグは JS の drag ハンドラより発火優先度が高い → CSS `pointer-events: none` で抑制必要
- [tip] 画像ドラッグ選択防止には `-webkit-user-drag: none` + `user-select: none` + `pointer-events: none` を組み合わせる。pointer-events は親要素へのイベントをバブルさせるのでリンク機能が保たれる。
- [pattern] Prestige のような paid theme では既存セクション名を変更せず、機能追加は新規セクション追加で対応するのが正解
- [tip] Shopify CLIセッション切れ時は `shopify auth login --store <store>.myshopify.com` または `--device-code` でセッション復旧可能
- [pattern] `shopify theme push --only layout/theme.liquid` で特定ファイルのみプッシュ可能。settings_data.json など不要な変更の混入を防ぐ
- [gotcha] Shopify CLI セッション切れ時、`shopify theme push` は `shopify auth login --store <store>` で再認証が必要。インタラクティブログインの場合はブラウザのコード入力も求められる
- [pattern] `settings_data.json` に変更がない場合、`shopify theme push --only <file>` で特定ファイルのみプッシュして不要な data.json 変更を回避
- [tip] Shopify CLI の認証が必要な操作は IDE ツール統合より、ターミナルで直接実行する方が確実（ブラウザ認証やコード入力が必要な場合）
- [pattern] Shopify Liquid のレスポンシブリンク対応：PC 用/モバイル用で別々の `<a>` 要素を用意し、`md:hidden`/`md-max:hidden` で表示制御すると、異なるリンク先でも保守性が高い
- [gotcha] `shopify theme push` 前に `config/settings_data.json` の diff を確認し、意図しない自動生成変更を含めていないか警告する
- [gotcha] Shopify CLI実行時は事前にストアドメインを確認。複数ストア運用時は `shopify theme list` で現在のコンテキストを確認必須
- [correction] ストア間違えています。今のリポジトリを確認して。
## 2026-04-28 | P130
- [correction] を明示的にしてあなたがプッシュするリポジトリを間違えないようにするにはどうすればいい？
- [gotcha] 結論: ストアドメイン自体は公開情報なのでリスクは低いですが、`.envrc` に何を書くかで扱いが変わります。以下、実務上の注意点。

- [pattern] Shopifyリポジトリの間違えプッシュ防止：direnv+SHOPIFY_FLAG_STORE固定 → pre-pushフック検証 → シェル関数確認の多層防御パターン。
- [tip] .envrc は .gitignore で除外し .envrc.example をコミット。store情報漏洩防止とチーム内柔軟性の両立。
- [gotcha] Shopify複数ストア環境で `shopify auth logout/login` を毎回手動実行するのは事故リスク。direnv + SHOPIFY_FLAG_STORE 固定 + pre-push フックで対象ストア認証を自動検証する。
- [pattern] .envrc は公開情報（store URL）のみコミット。トークン類は .envrc.local に分離して .gitignore + pre-commit フックで検出。
- [tip] Shopify トークン漏洩防止: pre-commit フックで `shpat_|shpca_|shppa_|shptka_` パターンを検出。GitHub push protection + gitleaks も併用。
- [pattern] Remote agentは別コンテキストで実行されるため、メイン会話のコンテキストを消費しない。結果テキストの返却分だけが消費される
- [pattern] headlessパターンで結果をファイル出力・通知のみにすれば、会話コンテキストへの影響をゼロにできる
- [tip] remote-control/RemoteTrigger/headless実行で動作が異なるため、コンテキスト圧迫回避が目的なら headless（別プロセス）を優先
- [gotcha] `git push` 前にリモート分岐の大きなズレを検出したら即座に `git fetch` + rebase/merge 判断が必須。先行/遅延が大きい状態での push は拒否される。
- [pattern] dotfiles や リモート関連の git 操作は `status` → `diff` → 分岐確認を順序固定で実施。untracked や分岐状態の見落とし防止。
- [gotcha] スキル実行で sync コマンド提示後、リモート分岐が大きい例外系は手動確認が必要。スキルは基本フローのみ、conflict/fetch失敗時は自動実行不可。
- [gotcha] ローカルが origin より先行していても、リモートに新しいコミットがあれば push は拒否される。分岐状態を事前に確認して rebase or force-with-lease を判断すべき。
- [pattern] マージコンフリクトで両側が有効な値の場合、片側を選ぶのではなく両方保持する設計も検討する（claude/settings.json のように）。
- [tip] 未ステージ変更がある状態での rebase は stash で保護し、rebase 後に pop して変更喪失を防ぐ。
- [gotcha] ヘッドレス環境（GitHub Actions）でのClaude CLI認証は$ANTHROPIC_API_KEYが必須。OAuthブラウザ認証は不可。
- [pattern] APIキーはdotfilesや設定スクリプトに含めず、.zshrc/OSキーチェーン/GitHub Secretsに個別設定。
- [tip] dotfiles同期は認証不要（git認証利用）、自動化パイプラインはsecrets経由、インタラクティブCLIはOAuth利用で使い分け。

- [pattern] macOS Keychain で API キー管理：1回保存で iCloud 経由で複数 Mac に自動同期、新環境初期化時のキー入力不要
- [pattern] Keychain → ~/.secrets フォールバック：存在確認→対話入力の段階的フロー、既存環境との後方互換性を両立
- [tip] GitHub Actions/ヘッドレス環境では GitHub Secrets 経由で環境変数注入、API キーをリポジトリに入れない

## 2026-04-20 14:00 | ANIECA_ver02 [ai]
- [gotcha] `.envrc` に Shopify token を書くと GitHub scanning 対象になり流出リスク。store URL のみコミット、token は `.envrc.local` で分離管理。

## 2026-04-21 13:21 | Beauty-Select
- [gotcha] > 注意: Shopify の Customer Segment API は比較的新しい。セグメント条件（`customer_tags CONTAINS 'userrank-gold'` 等）でディスカウントを制限できるか動作確認が必要。

- [pattern] Shopifyで月次ランク更新やディスカウント発行などの定期バッチ処理が必要な場合、GitHub Actions + Admin GraphQL API + Bulk Operations APIの組み合わせが標準。Shopify単体では実装不可。
- [gotcha] 顧客スケール（数百人 vs 数万人）でAPI選択が大きく変わる。実装前にスケール規模を確認しないと工数見積もりが2倍以上ズレる可能性がある。
- [gotcha] Customer Segment APIなど比較的新しいShopify APIでセグメント条件（タグ絞り込み等）を使う場合、ドキュメント通りに動作するか実装前のPoC確認が必須。
- [pattern] Liquidの`customer.tags`と`date`フィルタで当月コード（2026APR等）を動的生成できる。ランク別表示に有効。
- [pattern] Shopifyディスカウント+セグメントAPIはドキュメント例がユースケースと完全一致。標準機能で実装可、開発見通しが立つ。
- [gotcha] Shopify Admin GraphQL の `amount_spent` フィルタは「全期間合計のみ」で過去1年指定不可 → 期間ベースの顧客ランク計算は GitHub Actions スクリプト必須
- [tip] Liquid の日付フィルタ `'now' | date: '%Y%b' | upcase` でコード名「2026MAY」を自動生成可能
- [gotcha] Shopify のセグメント query 言語の `amount_spent` は全期間合計のみで「過去1年」指定不可。「過去1年購入額」ベースのランク計算は Admin API で注文を日付フィルタして集計するスクリプトが必須。
- [pattern] `account.liquid` はセクションシステム非対応。スニペット + `{% render %}` で実装し、テーマ設定を `settings_schema.json` で UI 化すると、月次のコード更新を非開発者が管理画面で対応可能。
- [tip] Shopify ディスカウント API の `segmentCreate` + `discountCodeBasicCreate` で顧客セグメント指定のコード発行が標準機能。セグメント制限も API から自動制御でき、後付けルール不要。
## 2026-04-21 14:32 | Pinup-Closet_ver01
- [gotcha] HTML IDにスペースは無効で、`getElementById` はスペース区切りの複合IDにマッチしない。devtoolsで確認した値は `class="fsb sr summary"` というクラス名を誤読した可能性が高く、Strategy 1 は全ページで必ず失敗する。

- [gotcha] HTML IDはスペース不可。`getElementById` で見つからない場合、devtoolsで見えるのはクラス名の可能性がある。セレクターなら `.class1.class2` または `[class*="keyword"]` を使用。
- [gotcha] DOM操作で属性をセット後にエラーが発生すると、属性だけ残って状態が不整合になる。`setAttribute` は操作成功後に実行し、try-catchで初期状態に戻す。
- [pattern] ロケール文字列・CSSクラス・IDの削除・変更前に全プロジェクト検索で他テンプレートへの影響を確認。複数箇所に依存していないか確認してからマージ。
- [pattern] DOM修正時、修正成功フラグ（`data-*` 属性等）は操作後に付与する。操作失敗時にフラグだけ残るとリトライが機能しなくなる。
- [gotcha] Shopify Dawn テーマの既存クラス（`title-wrapper-with-link` 等）をリネームすると定義済みスタイルが失われる。リネーム不要なら並存させるべき。
## 2026-04-27 13:18 | mimc.co.jp-mailmagazine
- [correction] 完了: 修正しました。変更内容：


- [pattern] メール HTML は複雑なテーブルレイアウトより `<p>` タグのシンプル縦並びが、メールクライアント互換性と修正効率の面で優れている。
- [tip] PDF 仕様書とスクリーンショットを並べ比較すると、期間表記・特典表示・画像配置の細かい違いが効率よく発見でき、実装前検証として有効。
- [pattern] キャンペーンボックス内のプレゼント表示は、複数商品サムネイル行より全幅画像 1 枚の方が、訴求力と収まりが良い。
- [pattern] メールHTML の縦方向余白は em、横方向は px で統一。相対単位がメールクライアント対応性に優れている
- [gotcha] CAMPAIGNボックス内の要素構成（画像の配置位置や数）はスクリーンショット確認なしに決定してはいけない。ユーザーのビジュアルフィードバックで修正
- [pattern] 複数ファイルの一括置換（px→em 変換など）が必要な場合、Pythonスクリプトで自動化して効率化
- [pattern] メールマガジンのプレゼント表示は複数商品のサムネイル行ではなく、横幅いっぱいの1枚画像（`0424_present.jpg`）が正解パターン
- [pattern] メール HTML の縦方向余白（top/bottom）はすべて em で統一；横方向は px のまま。Pythonスクリプトで一括変換可能
- [tip] メール環境での矢印記号は文字直書き`▶`より数値参照`&#9658;`が安全。Outlookを含めた広い互換性が必要な場合は数値参照推奨。
- [pattern] メールマガジンの期間・特典表示はテーブル要素ではなくp要素の段落で実装。テーブル構造はメールクライアント依存で崩れやすい。
- [correction] メールHTMLの右向き三角は▶直書きではなく`&#9658;`（数値参照）で実装 — 環境依存リスク対策
- [pattern] 複数商品表示は画像と説明を左右交互で縦並びレイアウトすると視覚的な動きが出て効果的
- [gotcha] メールHTMLで右向き三角を直書き（`▶`）すると環境依存リスク。`&#9658;` HTMLエンティティで統一すべき
- [pattern] Pythonで縦方向余白を一括変換：正規表現で縦方向`px`→`em`に、横方向は変更なし
- [tip] メール設定テンプレートはYAMLより`tomllib`（Python 3.13標準）TOML形式が簡潔で追加パッケージ不要
## 2026-04-27 20:13 | ohayoreuteri_theme [ai]
- [pattern] ecforce定期便テンプレートはshow/edit両方存在。片方の変更時は関連ページの整合性を確認（show側でクーポン非表示でもedit側入力フォームが残る場合など）
- [pattern] テーブル列非表示は戻す可能性で選択：不要ならHTML/Liquidから削除、戻す可能性あればLiquidコメント化
- [gotcha] ecforceテンプレートは行番号ベース指定が脆弱。行数変更で指定位置がずれる可能性。実装前に該当行を必ず確認

- [gotcha] ecforceテーマでUI要素を非表示にする際は、同じ機能が複数画面（show/edit等）に存在するか確認し、運用方針を決めてから実装すること
- [pattern] ecforceテーマの非表示機能は複数案（削除/CSS/コメント）を提示し、ユーザーに選択させるのが効果的。Liquidテンプレートではコメントアウトが可逆的で復活しやすい。
- [gotcha] show/edit など関連ページが複数ある場合、修正対象を明確にする。ユーザーが「詳細画面のみか、編集機能も一緒か」を判断する段階を挟まないと、後で仕様ズレが生じやすい。
- [tip] `{% comment %}...{% endcomment %}` でコメントアウトすれば、DOMに残らず、将来の復活や検証も簡単。削除との中間案として有用。

- [gotcha] ecforceの定期便テンプレートは表示画面（show）と編集画面（edit）が分離。一方だけ非表示にすると、編集画面からは操作可能という不整合が発生。要件時に確認必須
- [pattern] テーブル列の一時的非表示はLiquidコメント（{% comment %}...{% endcomment %}）推奨。完全削除より変更可逆性が高く、復活が簡単
- [tip] ecforceテーブル列非表示時は見出し（th）と値セル（td）の両方をコメント化。片方だけだと列幅がずれる

## 2026-04-28 | pietro-onlineshop_ver01
- [correction] フォントサイズが異なるところがあります。デザインに合わせて下さい。
- [correction] タブレット、SP版でバッジの表示が崩れてしまいました。修正して下さい。

- [gotcha] Shopifyテーマ開発でCDN配信のCSSは直接編集できない。Liquidの`<style>`タグやHTML構造の工夫でオーバーライドするか対応すること。
- [pattern] HTMLの要素順序変更で外部CDN依存のCSS差分を回避できる。CSSスコープが限定的なときの有効な戦略。
- [pattern] PDFデザイン仕様確認時に「行間」「フォントサイズ」「マージン」を数値化し、既存CSS値と並べて比較する。目視だけでなく数値化することで調整箇所が明確になり、修正回数が減る。
- [gotcha] Shopify CDN CSS の基準値（例：`min-width: 1367px`）を最初に確認しないと、後で px→vw 変換が何度も発生。計算基準を先に定める
- [pattern] レスポンシブフォントサイズ調整は「基準ブレーク内のpx値 → vw比率に逆算 → clamp統一」の3段階で進めると、複数ブレークポイント間の破綻が少ない
- [gotcha] `shopify theme push`実行前に認証有効期限を確認。切れていたら`shopify auth login`で先に再認証する
- [pattern] レスポンシブ値を`clamp(min, vw, max)`から純`vw`に統一すると、計算・保守がシンプル化。PC/SP両対応時は特に有効
- [tip] px/vw/clamp混在の調整は後から統一するより、最初から単位戦略を決めると手戻りが減る

## Recurring Patterns (updated 2026-05-15)
- [shopify] メルマガでSKUと画像の整合性確認が必須 — seen 5 times
- [shopify] Shopify CLI認証セッション切れに注意 — seen 6 times
- [general] dotfiles symlink/git同期は破損リスクあり、定期チェック必須 — seen 4 times
- [email] メルマガ認証・URL・UTMはテンプレート流用時に全確認 — seen 3 times
- [general] GitHub Actions YAMLは複数行文字列・APIキー設定に注意 — seen 4 times
- [ecforce] ecforceはshow/editの両方を確認 — seen 5 times
- [email] メールHTML縦方向余白はem統一 — seen 3 times
- [general] APIキー管理は環境別に分類（dotfiles/GitHub Secrets/OAuth） — seen 4 times
- [css] レスポンシブ単位は最初に統一戦略を決める（clamp/vw/px） — seen 3 times
- [shopify-app] アプリ削除で client_id が変わる — seen 7 times
- [shopify] settings_data.json はtheme push前に差分確認・unstage必須 — seen 4 times
- [shopify] Liquidメタフィールドの`.value`はOS2.0で不要（重ねるとnil） — seen 3 times
- [shopify] Shopify複数ストア管理はdirenv+SHOPIFY_FLAG_STORE固定が必須 — seen 5 times
- [shopify] Shopifyアプリ削除後はDiscountリソース再作成が必要 — seen 5 times
- [git] git push前にリモート分岐確認が必須 — seen 6 times
- [email] メールHTML修正はPDF仕様書との視覚確認が必須 — seen 6 times
- [general] テキスト修正と画像差替えは分離PRで競合を防ぐ — seen 5 times
- [shopify] Shopify Functionはディスカウント前提条件がないと動作しない — seen 5 times
- [general] Python one-linerで複数ファイル一括置換が効率的 — seen 9 times
- [shopify] JS制御UI要素のFOUC防止：HTMLデフォルト非表示でJSで解除 — seen 3 times
- [email] メールHTMLの空<p>タグは&nbsp;か<hr>で代替（直書きは崩れる） — seen 4 times
- [email] <img>のwidth属性にパーセント指定不可、インラインスタイルのみ — seen 3 times
- [shopify] ローカライゼーションキーはen.default.jsonにも同時追加が必須 — seen 3 times

## 2026-05-14 16:34 | GitHub
- 作業: <command-message>doctor</command-message>
- 完了: - リモートの先行コミット（`improve-autonomous-learning`、`notebooklm-integration-check`ブランチ追加）をrebaseでマージしてpush
## 2026-04-27 20:17 | ohayoreuteri_theme [ai]
- [pattern] ecforceの定期便機能では show/edit ページが独立した フロー。詳細表示と編集フォームの表示・非表示を切り分けて検討する。
- [pattern] Liquidテンプレートで列を一時的に非表示にする場合、{% comment %} でコメント化すると復活が容易。短期的な仕様変更に有効。

## 2026-04-30 11:23 | pietro-onlineshop_ver01
- > 注意: WPD App は `snippets/wcp_cart.liquid` でドメイン変数として参照されているだけで、実際にカートで使われているかはフロー次第です。確認が必要であれば調べます。

## 2026-04-30 11:25 | pietro-onlineshop_ver01 [ai]
- [gotcha] Shopify CLI でアプリ一覧取得には `shopify store auth --store <domain> --scopes read_apps` で事前認証が必須（スコープ指定が必須）
- [tip] Admin API の `appInstallations` クエリは追加スコープ不要で実行可能（read_apps スコープで十分）

## 2026-04-30 11:25 | pietro-onlineshop_ver01 [ai]
- [gotcha] テーマ内コード検索（App Proxyエンドポイント）とAdmin API `appInstallations` クエリは確認する領域が異なる。前者は「テーマで参照」、後者は「実際にインストール」。両方で確認すべき。
- [pattern] Shopifyテーマのアプリ統合は App Proxy URL (`/apps/xxx`) でコード内に記載されるため、snippet/section検索で用途を特定できる。設定値の参照有無で本番/開発環境の切り替え判定も可能。
- [tip] `appInstallations` クエリ実行時はストアドメイン（`<store>.myshopify.com`）が必須。未設定なら `shopify store auth --scopes read_apps` で初期認証が必要。

## 2026-04-30 11:28 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopify Admin APIの`appInstallations`クエリで`shopify store auth` → `shopify store execute`でインストール済みアプリ一覧を取得可能。id、title、handle、launchUrl、accessScopesなどが取得できる
- [gotcha] `.shopify/project.json`にストアドメインが設定されていない場合、`shopify store auth --store <domain>.myshopify.com` で手動指定してから実行コマンドを実行する必要がある
- [tip] テーマファイル内の参照（Liquid/JS grep検索）とAdmin API確認を組み合わせると、実装されているアプリと実際にインストール済みのアプリの両方を把握できる

## 2026-04-30 11:28 | pietro-onlineshop_ver01 [ai]
- [gotcha] `shopify store auth` はローカルサーバーをポート 13387 で起動するため、既に使用中だと失敗→ `lsof -ti:13387 | xargs kill -9` で解放が必須

## 2026-04-30 11:29 | pietro-onlineshop_ver01
- [pattern] `read_apps` は標準のOAuthスコープとして存在しないため、このアプローチは機能しません。

## 2026-04-30 11:29 | pietro-onlineshop_ver01 [ai]
- [gotcha] `shopify store auth` の `read_apps` スコープは標準では存在しない。Admin APIでアプリ一覧を取得する際は、標準スコープの確認が必須。
- [pattern] テーマ内のコード参照（App Proxy URL・スニペット）からアプリ依存関係を逆引きできる。GraphQL APIが必要でない場合も多い。
- [tip] インストール済みアプリ一覧は管理画面 → 設定 → アプリと販売チャネル で直接確認が最速。URL: `https://admin.shopify.com/store/{store}/settings/apps`

## 2026-04-30 16:55 | mimc.co.jp-mailmagazine
- [open] 要確認事項:

## 2026-04-30 16:55 | mimc.co.jp-mailmagazine
- [correction] 3. **画像パス** — `2026/0508_kv.jpg`、`0508_01.jpg`〜`0508_04.jpg` を想定。実際のファイル名が異なる場合は修正します

## 2026-04-30 16:55 | mimc.co.jp-mailmagazine [ai]
- [pattern] メルマガHTML作成は「PDF構成読込 → 既存テンプレート参考 → 商品情報・画像パス確認」のステップで進める
- [gotcha] PDFのURL情報は末尾が不完全な場合が多い。商品コード（gMLE-など）を正確に確認してから実装する
- [tip] 画像パスは推定ではなく実ファイルの命名規則（2026/MMDD_XX.jpg）を事前に確認しておく

## 2026-04-30 17:00 | mimc.co.jp-mailmagazine
- 作業: <ide_opened_file>The user opened the file /Users/P130/GitHub/mimc.co.jp-mailmagazine/CLAUDE.md in the IDE. This may or m
- 完了: [260508.html](260508.html) を作成しました。

## 2026-04-30 17:00 | mimc.co.jp-mailmagazine
- [open] - [tip] 商品リンク生成時、PDFから抽出した商品コードは末尾が切れることがあるため、正確性を要確認。

## 2026-04-30 17:00 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メルマガコーディング時、KVセクションの「詳しくはこちら」ボタンは必須要素。初版で見落としやすい。
- [pattern] MIMC メルマガは構成が定型化：KV（ボタン付き）→ RECOMMEND（複数商品）→ PICKUP → mnb バナー群 → SNS/フッター。テンプレート化で初期作成時間を短縮可能。
- [tip] 商品リンク生成時、PDFから抽出した商品コードは末尾が切れることがあるため、正確性を要確認。

## 2026-04-30 17:00 | mimc.co.jp-mailmagazine
- [pattern] 黒背景・白文字に修正しました。

## 2026-04-30 17:01 | mimc.co.jp-mailmagazine
- - [correction] ユーザーからの修正指示（色違い等）に対しては即座に対応。メール HTML は環境依存の表示差異が大きいため、確認反復が重要

## 2026-04-30 17:00 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メール HTML テンプレートはデザイン PDF の構成要素が抜け落ちやすい。完成後に PDF と 1 対 1 で照合し、ボタン・色・テキストを検証する
- [pattern] メルマガボタンのスタイル（背景色・文字色）はデザイン PDF で明示的に確認し、既存テンプレートとの色一貫性を保つ
- [correction] ユーザーからの修正指示（色違い等）に対しては即座に対応。メール HTML は環境依存の表示差異が大きいため、確認反復が重要

## 2026-04-30 17:04 | mimc.co.jp-mailmagazine
- 完了: 黒背景・白文字に修正しました。

## 2026-04-30 17:04 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メール HTML のボタンスタイル（色・背景）はPDFデザイン確認後に実装（初期版で不確定なまま進めない）
- [pattern] メール画像は `width="100%" style="max-width:100%;"` で幅100%対応する

## 2026-04-30 17:13 | mimc.co.jp-mailmagazine
- 構造・スタイル・utm パラメータの基本品質は良好です。ただし、重要度の高い問題が2件、確認が必要な点が複数あります。

## 2026-04-30 17:13 | mimc.co.jp-mailmagazine [ai]
- [gotcha] 空の `<p>` タグはメールクライアントで高さが崩れる可能性。セパレーターが必要な場合は `&nbsp;` か `<hr>` を使うべき
- [gotcha] `<td>` に `margin` を指定してもメールクライアントで無視される。メールHTMLではパディングと高さで余白を制御する
- [pattern] キャンペーンメールの全リンクに `utm_source=mailmagazine&utm_medium=email&utm_campaign=YYMMDD` を統一付与すると分析精度が向上

## 2026-04-30 19:31 | mimc.co.jp-mailmagazine
- 作業: ## Code Review Request
- 完了: mnb セクションで `<div>` を使用していますが、260505.html でも同様のパターンを使用しています。Outlook 2007-2019 では `<div>` のマージン・パディングが信頼できない場合があります。ただし、260505.html との一貫性を考慮すると、現時点での変更は

## 2026-04-30 19:31 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メールHTMLの空 `<p>` タグはメールクライアントで高さが崩れるため、区切り線として使う場合は `&nbsp;` か `<hr>` を使う
- [gotcha] `<img>` の `width="100%"` はHTML属性としては無効（ピクセル値が期待される）。パーセント指定はインラインスタイル `style="width:100%"` にのみ記述する
- [pattern] KVボタンや商品リンクのキャンペーンURLは配信前に実在確認必須。存在しないパスは404になるため、utm付与と同時にリンク先の実在チェックをチェックリストに組み込む

## 2026-04-30 19:35 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メールHTMLの空`<p>`タグはメールクライアントで高さが崩れる場合があるため、区切り線として使う場合は`&nbsp;`を入れるか`<hr>`に置き換える
- [gotcha] `<img width="100%">`のHTML属性`width`はピクセル値を期待するため、パーセント指定はインラインスタイル（`style="max-width:100%"`）のみに頼るべき
- [pattern] 参照元ファイル（260505.html）の二重`<tr>`バグを引き継がず修正できた——パターン踏襲時も構造差分を目視確認することで既存バグの伝搬を防げる

## 2026-04-30 19:55 | mimc.co.jp-mailmagazine [ai]
- [gotcha] メールHTMLの空 `<p>` タグはメールクライアントで高さが崩れる場合があるため、区切り線目的で使う場合は `&nbsp;` か `<hr>` を使う
- [gotcha] `<img>` の `width="100%"` はHTML属性としてはピクセル値を期待するため、パーセント指定はインラインスタイル（`style="max-width:100%"`）のみで行う
- [pattern] 既存HTMLをテンプレートとして流用する際は二重 `<tr>` タグなどの既存バグを引き継がないよう、パターン元ファイルのバグを認識した上でコピーする

## 2026-05-07 11:53 | P130
- [correction] | 旧（間違い） | 新（正しい） |

## 2026-05-07 11:53 | P130 [ai]
- [pattern] 外部API統合デバッグ時、ドキュメント参照とコード実装を並行確認し、エンドポイント・フィールド名・認証情報を対応表で検証する。複数ずれを同時に見つけやすい
- [gotcha] RESTful APIでリソースIDがパス必須の場合（XServer等）、環境変数未設定なら403エラー。認証設定チェックリストに「パスに埋め込むID」を明示する

## 2026-05-07 11:53 | P130 [ai]
- [gotcha] XServer APIのエンドポイントはバージョン付き（`/v1/...`）で、ドメイン取得・DNS操作ごとにパスが異なる。`/domains` ではなく `/v1/server/{servername}/domain` など必ずドキュメント確認必須
- [gotcha] XServer API呼び出しにはサーバー名がパスに必須。コンソール「サーバー情報」から `sv12345` を確認し、`sv12345.xsrv.jp` フル形式で設定
- [pattern] 外部API連携時はレスポンス構造の事前確認。XServerはフィールド名が `value` → `content`、`name` → `host` など非直感的。ドキュメントとスクリプトの並行確認がデバッグ時間を短縮

## 2026-05-07 11:54 | P130 [ai]
- [gotcha] XServer APIはエンドポイントパス・フィールド名・サーバー名形式が全て非自明（/domains→/v1/server/{servername}/domain、value→content等）。ドキュメント照合なしに実装すると確実に失敗する。
- [pattern] 403 FORBIDDENエラーはコード修正より先にアカウント管理画面のAPIキー権限・対象サーバー設定を確認。root causeは大抵権限設定側。
- [correction] サーバーIDとサーバーFQDNは別。XServerではサーバーパネル「サーバー情報」の実名（例: cingroup2.xsrv.jp）をAPI呼び出しに使用。

## 2026-05-07 11:54 | P130 [ai]
- [gotcha] XServer APIのエンドポイントはパスにサーバー名を含める形式（`/v1/server/{servername}/domain`）。この構造を見落とすと全リクエストが失敗する
- [gotcha] APIレスポンスのフィールド名（`value` vs `content`、`name` vs `host`）がドキュメント記載と異なる場合がある。実装前に必ずドキュメントとスキーマを照合
- [tip] XServer 403エラー時、コード問題の前に管理画面でAPIキーの「対象サーバー」設定を確認。キーが特定サーバーにのみ権限を持つ可能性

## 2026-05-07 13:11 | teras-taya
- 重要な情報があります。このファイルについてすでに観測が記録されています。詳細を取得します。

## 2026-05-07 13:10 | teras-taya [ai]
- [gotcha] localStorage.setItem() は Safari プライベートブラウジングで SecurityError を throw する。重要な UI操作は必ず try/catch で囲む必須。
- [pattern] Flash-of-content を防ぐには、デフォルト HTML 状態を非表示（aria-hidden="true"）にして、JS で必要な場合だけ解除する逆転パターンが確実。
- [gotcha] Shopify テーマで locale キーを追加するとき、base locale（en.default.json）に同時に追加していないと theme check で警告される。

## 2026-05-07 13:22 | teras-taya
- ### Critical（リリース前に必ず修正）
- [correction] #1〜#7まですべて修正してください

## 2026-05-07 13:22 | teras-taya [ai]
- [gotcha] ポップアップをHTML側で表示状態にしておくとFOUC発生。JS実行前に一瞬見える。デフォルトは `aria-hidden="true"` にしてJS側で条件判定時に外す
- [gotcha] Shopifyで `ja.json` にキーを追加したら `en.default.json` にも同じキーを英語値で追加必須。フォールバック仕様で英語ユーザーに生キー名が表示される
- [tip] CSS `transform: scale()` を常時適用するなら実寸をコメントで明記。宣言値と実態の乖離で将来の編集者が混乱する

## 2026-05-07 13:23 | teras-taya [ai]
- [gotcha] Shopify themeでポップアップ等のJS制御UI要素は、HTML側でデフォルトを隠す（aria-hidden="true"やdisplay:none）ことが必須。そうしないとJSが実行される前に一瞬表示されてしまう（FOUC）。
- [gotcha] Shopifyのローカライゼーション：テーマキーを `ja.json` に追加しても、Shopifyは `en.default.json` をフォールバックとして使うため、スタッフアカウントが英語設定だと生キー名が出力される。すべてのキーを `en.default.json` にも登録すること。
- [pattern] CSS で `scale()` 等の変換値を使う場合、宣言値と実表示サイズがズレるため、実寸ベースで設計し直すか、実寸をコメントで明記してメンテナンス性を高める。

## 2026-05-15 10:08 | dotfiles [ai]
- [pattern] settings.json のコンフリクト解決時、nightly自動管理部分とユーザー設定部分（editorMode等）を分離して採用する
- [pattern] ローカル独自コミットとリモート変更が競合する場合、内容確認後rebaseで再適用する
- [tip] 大幅分岐（100+コミット差）での同期は git rebase で対応、単純プッシュではNG

## 2026-05-15 10:09 | dotfiles [ai]
- [gotcha] dotfiles rebase 時のシンボリックリンク管理 — `~/.claude/` 配下ファイルは symlink 先のため、rebase/merge コンフリクト時に意図しない挙動が起こる可能性。次回はリベース前にリンク構造を明示的に確認する。
- [pattern] 大幅分岐時の HEAD 採用戦略 — リモート HEAD が nightly 統合済みの場合、HEAD を基準に adopt しつつユーザー設定（`editorMode` など）のみ選別的に保持すると効率的。
- [tip] 無関係な変更は先にスタッシュ — rebase 前に `.zshrc` など無関係ファイルをスタッシュすると、コンフリクト解決が単純化される。
