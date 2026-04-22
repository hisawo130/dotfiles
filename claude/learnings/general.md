# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## メール / HTML

- [tip] メルマガHTMLで `!important` は Outlook 回避用として有効
- [gotcha] PDFや画像内のテキストが読み取れない場合、推測で文章を作らず必ずユーザーに確認する。特にメール本文・商品説明文など正確さが重要なコンテンツは勝手に創作しない。

## JavaScript / フロントエンド

- [pattern] fetch成功判定は `res.ok` を必ず確認する。成功時だけ状態を記録し、失敗時は再試行できるようにする。
- [pattern] 非同期初期化待ち: `.dd-button.click()` のようなDOM依存呼び出しではなく `window.discountDeckInstance.showCoupons()` を直接呼び出す — ポーリングで初期化を待つ実装に合わせるため。
- [open] Rivyoが `DOMContentLoaded` より後にバッジを注入する場合は `MutationObserver` への変更が必要になる可能性がある（実装後に確認）。

## コードレビューループ（Gemini / AI レビュー）

- [pattern] AI レビュー（Gemini 等）は同じ指摘を逆方向に繰り返すことがある（stopPropagation ↔ stopImmediatePropagation 等）。3回以上往復したら循環と判断し、技術的に正しい方を選んで固定する
- [correction] ユーザーから「致命的なエラー以外は修正しなくていい」と言われたら、スタイル・アクセシビリティ改善・命名規則の指摘はスキップし、バグ・セキュリティ問題のみ対応する
- [gotcha] AI レビューの提案が「以前試して動かなかった修正」と一致する場合は適用しない。過去のコミット履歴で既検証済みと明記してスキップする

## Git / dotfiles

- [pattern] save-learnings.sh の再帰防止: `CLAUDE_LEARNING_EXTRACT=1` 環境変数で自己呼び出しをガード
- [pattern] 追記専用ファイル（learningsログ等）のgitコンフリクト自動解消: `.gitattributes` に `claude/learnings/*.md merge=union` を設定する
- [pattern] dotfiles push前に `git pull --rebase` を実行して non-fast-forward エラーを防ぐ。learningsは `merge=union` で自動解消されるため手動マージ不要。

## MIMC / 案件固有

- [correction] `<div class="item_ttl">` は背景色ラベルになっている — デザインファイル(DF)に合わせること

## 2026-04-03 | dotfiles

- [tip] `/capture` スキルを使って重要な学びを手動で保存する運用の徹底
- [pattern] `pull --rebase` でコンフリクト → abort
- [tip] ルールベースなので「文脈的に重要」な学びは取れない

## 2026-04-02 | Pinup-Closet_ver01

- [tip] 注意点： localStorageに既に保存されている閲覧履歴には `productline` が含まれていないため、再訪問時に初めてラベルが保存されます。古い履歴はラベルなしで表示されます。

## 2026-04-10 | Pinup-Closet_ver01 [ai]

- [gotcha] 管理画面ページコンテンツのHTMLから参照する要素（data-remodal-target等）は、テーマ側で無条件レンダリングされているか確認必須。Liquid条件分岐で出力制限されていると該当ページに存在しない
- [pattern] product contextやページタイプに依存するモーダルは、複数ページから参照される可能性がある場合、条件を緩和するか汎用版を用意する
- [tip] Remodal実装時は、data-remodal-id と data-remodal-target の対応をテンプレートとJS両面から検証する
- [gotcha] Shopifyテーマで条件付き出力されるコンポーネント（モーダル、スニペット等）は、参照元が複数ページタイプにまたがる場合、すべてのコンテキストで出力されるか条件を見直す必要がある
- [pattern] モーダル不表示の調査は、ボタンの`data-remodal-target`値から逆引きして対応する`data-remodal-id`のHTML定義を探すことから始める
- [correction] 新しいモーダルを追加する前に、対象商品が既存のモーダルをどう参照しているか確認し、一貫性を保つべき
- [gotcha] LPページはproduct contextを持たないため、`if product.id == ...` で条件分岐されたモーダルHTMLは出力されない。汎用モーダルはページ本文またはテンプレート上部に無条件で配置する必要がある
- [pattern] Shopify管理画面のページコンテンツに定義されたモーダル（`data-remodal-id`）に対して、テーマのJS側でクリックハンドラをオーバーライドすることで機能追加できる（Sireneの例参照）
- [tip] モーダルが動作しない場合、`data-remodal-target` 値がHTMLに存在するか確認する際、ページコンテンツ（Shopify管理画面）とテンプレート両方をチェックが必須
- [gotcha] Shopifyテーマで `data-remodal-target` を使う場合、モーダルのHTML本体が `page.content`（管理画面ページ本文）内に定義されているか、テーマファイル内に定義されているか必ず確認する。テーマファイルだけでは完全な構造は見えない。
- [pattern] Shopifyテーマで同一コンポーネント（モーダル等）が複数LPで使われる場合、JSオーバーライドで動作をページごとにカスタマイズするアプローチ（Sireneの事例）が保守性が高い。Liquid条件分岐より柔軟。
- [tip] Shopifyテーマのモーダル実装確認はブラウザDevToolsで `data-remodal-id` 属性の有無を検査するのが最短。テーマファイルと管理画面を行き来するより効率的。
- [gotcha] Shopify LP ページではproduct contextがないため、layout/theme.liquid の商品ID条件分岐（`if product.id == ...`）内で定義されたモーダルは表示されない。LP用モーダルは条件を変更するか別途定義が必要。
- [pattern] Shopify LPページでモーダル機能を実装する場合、Sireneパターン（page.contentにHTMLを直書き + ページテンプレートでJSオーバーライド）を踏襲。modal-sireneのように `data-remodal-id` でページ本文に定義し、ページテンプレート側でイベントハンドラを追加。
- [tip] モーダル問題が複数ある場合、ブラウザデベロッパーツールで実際にレンダリングされているHTMLを確認し、page.content内のモーダル定義状況を把握してから修正。テーマファイルだけでは管理画面コンテンツ確認不可。
- [gotcha] page.content（Shopify管理画面で編集するページ本文）に埋め込まれたHTMLはテーマテンプレート分析では見えない。モーダルIDとボタンターゲットのペアリング検証にはブラウザ検査が必須。
- [gotcha] 条件付きレンダリング（`if product.id == ...`）でモーダルを出力すると、そのコンテキストにない場所（LP等）ではHTML本体が存在しない。ボタンのみ存在する矛盾状態になる。
- [pattern] LP固有UI実装パターン：モーダルHTMLはpage.contentに定義、JSハンドラはpage.lp-corset*.liquidで層分離する。ブランド追加時、LiquidはLP条件のみ、JSハンドラを足すだけで拡張可能。
- [gotcha] Shopifyテーマでpage.contentに埋め込まれたHTMLモーダルはテーマファイルには見えない。ブラウザのデベロッパーツールで実際に`data-remodal-id`が存在するか確認が必須。
- [gotcha] 商品ページ向けに`if product.id == ...`条件でモーダルHTMLをレンダリングすると、product contextを持たないLPページでは出力されない。複数ページタイプで使うモーダルは条件設計に注意。
- [pattern] Shopifyテーマで複数ブランド向けモーダルを実装する場合、LiquidファイルのJSオーバーライド箇所で各ブランドID毎のハンドラを定義し、page.content側で共通のdata-remodal-idを指定する構造が統一的。
- [gotcha] Shopifyテーマで page.content 内のボタンと theme.liquid のモーダル定義が分離していると、page.content からは見えない product context 条件分岐でモーダルが非表示になることがある。LPページでは product context がないため注意。
- [pattern] モーダル実装は「HTML定義（Liquid）＋イベントハンドラ（JS）＋ボタンの data-remodal-target」の3点セット確認が必須。1つ欠けると動作しない。
- [tip] page.content に書かれた data-remodal-target の値とテーマ側の data-remodal-id が一致しているか、ブラウザのデベロッパーツールで実HTML をレンダリング確認するのが確実。
- [gotcha] Shopifyテーマの`page.content`内のHTML要素はLiquidテンプレートから見えない。ページコンテンツ関連のデバッグ時はブラウザまたは管理画面での直接確認が必須。
- [gotcha] ページコンテンツで指定した`data-remodal-target`などのIDに対応するHTMLやJSハンドラがテーマ側に存在しないと動作しない。ページ側とテーマ側の整合性確認が重要。
- [pattern] LPページなど複数の場面で再利用するモーダル・コンポーネントは、`if product.id == ...`の個別条件で制限せず、より広いスコープで定義する。
- [gotcha] Shopify theme で page.content（管理画面コンテンツ）に埋め込まれた HTML と Liquid テンプレート内のモーダル定義は、テーマファイルだけでは対応関係を検証できない。button の data-remodal-target が実装前に page.content の構造を確認必須。
- [pattern] LP やページ固有のモーダル JS オーバーライド（イベントハンドラ追加）は、そのページテンプレート（page.lp-corset01.liquid など）に直接記述するとロジック と使用箇所が一緒に管理でき保守性が上がる。
- [tip] 複数の商品/モーダル種類がある場合、各モーダルの使用条件（product context 有無、ページタイプ等）と data-remodal-target の対応を一度整理してから修正すると、ボタン-モーダル不一致を防ぎやすい。
- [gotcha] Shopifyテーマで商品ページ専用モーダル（`if product.id == ...`条件）をLP/ページから呼び出す場合、HTMLレンダリング条件を確認が必須。ボタンのターゲット指定だけでは不足。
- [pattern] 複数ブランドのLP診断モーダル（Sirene/Sylphide）は`page.content`HTML定義 + テンプレート側のブランド別JSオーバーライドパターンで管理する（PR #26から）。
- [gotcha] モーダル動作失敗は複合原因（HTML未出力 + JSハンドラ未定義）の場合がある。両方をセットで確認する。
- [gotcha] Shopify page.contentに埋め込まれたHTMLはテーマLiquidから見えない。モーダルやボタンの挙動を調査する際は、管理画面コンテンツとテーマファイル両方を確認必須
- [pattern] テンプレート内のモーダルをproduct ID条件で制限すると、商品ページ以外（LP）で参照されて破綻する。複数ページで共用する場合は `request.page_type` ベースの条件分岐が拡張性が高い
- [tip] カスタムモーダル実装時は、JSハンドラ（クリックイベント）とHTMLの存在を同時に確認。一方だけでは動作しない
- [gotcha] Shopifyページ（page.content）のHTML内容はテンプレートから見えない。ボタン実装とモーダル不一致の原因特定には、ブラウザのデベロッパーツール確認が必須。
- [gotcha] LP ページは product context がないため、商品ページの `if product.id == ...` 条件でレンダリングされるモーダルは LP では出力されない。LP 用と product 用の条件分岐を分離して管理する必要がある。
- [pattern] 複数 LP ページで複数モーダルを使う場合、page.content に各モーダル HTML を定義し、テンプレート側（page-xxx.liquid）で JS オーバーライドする二層構造が有効。
- [gotcha] page.contentの管理画面HTMLと.liquidテンプレート内のHTMLは別物。デベロッパーツールでpage.contentのHTMLを確認しないと、テーマファイルだけでは検証不完全。
- [pattern] product contextが必須なUIは条件分岐で出力制限されることが多い。LPページなど異なるコンテキストで使う場合は、テンプレートの条件を拡張してHTMLが出力されることを確認する。
- [gotcha] モーダルやボタン実装では、HTMLの`data-remodal-id`定義とJSのイベントハンドラ両方が揃っていないと動作しない。片方だけでは不完全。
- [gotcha] Shopifyテーマで複数ページでモーダルを共有する際、page.content（管理画面）のHTMLと`layout/theme.liquid`のHTMLの乖離を必ず確認する。product contextがないページではモーダルHTMLが出力されない可能性がある。
- [pattern] テーマの既存実装パターン（例：Sirene用のJS実装）を参考に、同様の構造を別機能（Sylphide）に適用する方式が有効。一度動いているパターンを流用するほうが安全。
- [gotcha] 商品ページの条件分岐内（`if product.id == ...`）でレンダリングされるコンポーネントは、該当ページのproduct contextがないLPページでは描画されない。複数ページで共有するモーダルの条件分岐を見直す際に注意。

## Recurring Patterns (updated 2026-04-21)
- [javascript] stopImmediatePropagation required (not stopPropagation) when jQuery delegated + document-level listeners coexist — seen 12+ times
- [javascript] Web Component disconnectedCallback must clear all timers and listeners; AbortController simplifies bulk cleanup — seen 10+ times
- [javascript] async scroll side effects (instantJump) must be separated from return values to prevent scrollend race conditions — seen 9+ times
- [javascript] High-frequency event handlers (pointermove): cache getComputedStyle/offsetWidth at drag-start, reuse cached value — seen 8+ times
- [javascript] transitionend: use generation counter to detect and skip stale callbacks from superseded animations — seen 7+ times
- [shopify] Shopify page.content modal HTML is invisible to Liquid templates; verify data-remodal-id via browser DevTools — seen 7+ times
- [shopify] Shopify app deploy: client_id in toml must match an app in the currently-logged-in Partner organization — seen 6+ times
- [shopify] webpack/Sass build failure can delete entire CSS output file; restore via git show before adding new styles — seen 5+ times
- [shopify] settings_data.json is auto-synced; always unstage before committing to avoid main-branch conflicts — seen 4+ times
- [shopify] complementary_products metafield may include the current product; add product.id skip check inside loop — seen 3+ times
- [shopify] Prestige theme section spacing: set --section-vertical-spacing-override CSS custom property, not margin/padding directly — seen 3+ times
- [shopify] OS2.0 Liquid metafield: .value accessor not needed; customer.metafields['ns']['key'] already returns the value — seen 3+ times
## Recurring Patterns (updated 2026-04-19)
- [shopify] Liquid — seen 24 times
- [shopify] Shopify CLI — seen 6 times
- [api] metafield — seen 5 times

## Recurring Patterns (updated 2026-04-19)

## Recurring Patterns (updated 2026-04-19)

## Recurring Patterns (updated 2026-04-19)
## Recurring Patterns (updated 2026-04-20)
- [js] pointermove layout thrashing — seen 37 times
- [js] transitionend/scrollend event — seen 28 times
- [shopify] remodal/modal — seen 21 times
- [js] stopImmediatePropagation — seen 21 times
- [shopify] page.content modal — seen 21 times
- [js] disconnectedCallback cleanup — seen 18 times
- [js] instantJump carousel — seen 15 times
- [shopify] Shopify deploy Partner Dashboard — seen 15 times
- [js] generation counter — seen 11 times
- [js] AbortController — seen 10 times
- [shopify] metafield import — seen 8 times


## 2026-04-06 | dotfiles [ai]

- [gotcha] Chrome DevTools MCPはデフォルトで使用統計をGoogleに送信（`--no-usage-statistics`で無効化必須）
- [pattern] Shopify/ecforceテーマ開発でビジュアル確認・JavaScriptデバッグをMCPで自動化できる
- [tip] Chrome DevToolsトレース取得によるパフォーマンス分析がエージェント実行時に活用可能

## 2026-04-06 19:49 | idol-anime.com [ai]
- [gotcha] Chrome を `--remote-debugging-port=9222` で起動していないと MCP が接続できない — CLI起動が必須
- [gotcha] 既存の Chrome セッションではなく新しいインスタンスで起動するのが確実。同時起動で動作不安定になりやすい
- [tip] `claude mcp list` で登録済みサーバーを確認してから使用。パッケージ名と MCP サーバー名が異なる場合がある

## 2026-04-10 10:33 | P130 [ai]
- [gotcha] ユニークコード1回限り有効の実装は、ランダム関数だけでは不十分。事前生成したコード一覧をDBで管理し、使用済みフラグで制御する必要がある。
- [pattern] 大規模キャンペーン（万単位の対象者）のLP・コード検証機能は、納期が短い場合（5月公開予定）、既存ECカートのテンプレートやノーコード施策で検討。完全カスタム構築は納期超過リスク。
- [gotcha] 年齢確認（アルコール飲料対応）の法的責任と実装方法（本人確認・配送時確認）を事前に確認。提携企業の責任分担も明確化すべき。

## 2026-04-10 12:23 | Pinup-Closet_ver01
- [correction] 具体的には条件を変更します。修正してよいですか？

## 2026-04-10 13:30 | P130
- [open] - 楽天スーパーロジスティクス・オープンロジ（中小向けB2C、酒類可否要確認）

## 2026-04-10 13:30 | P130 [ai]
- [gotcha] 「EC機能が必要」と予想してECカート選定を進めると、決済・カート・商品管理の過剰機能で開発期間超過。キャンペーン申込＋コード照合のみならFormrunやカスタムLPで十分
- [pattern] 酒類配送が必要な場合、ECカートではなく「酒類倉庫業許可を持つ3PL業者」を先に決定してLPと分離。キャンペーン専業会社なら一括受託可能
- [tip] ユニークコード10,000個の管理は、事前CSV生成 → DB格納 → 申込時照合・使用済みフラグ更新で実装。ランダム生成ロジックより運用が単純

- [gotcha] 2. 酒類の年齢確認 → 法的要件（酒税法・未成年飲酒禁止法）の確認が必要

- [gotcha] 見た目はEC案件でも、決済機能が不要なら過剰装備化する。要件の本質を見極めることが重要
- [pattern] 複合案件（LP＋コード管理＋物流）はスコープを分割し、デジタル部分と物流部分の対応範囲を早期に明確化する
- [tip] 酒類キャンペーンは年齢確認法務・3PL酒類対応可否・役割分担を受注前に全て確認する必要がある




## 2026-04-10 14:06 | pietro-onlineshop_ver01 [ai]
- [gotcha] Shopifyのリダイレクト機能はクエリパラメータをマッチング条件に使えない。パス部分のみが対象で、`&cc=CA057` をつけると完全一致しない。
- [pattern] 旧商品コードを新URLへ振り分ける際、パラメータバリエーションが多い場合は、`theme.liquid` のJSマッピング+`location.replace()` が複数リダイレクト登録より効率的。
- [tip] Shopifyリダイレクトでクエリパラメータ対応が必要なら、リダイレクトアプリ導入（Traffic Control等）またはJS転送実装を検討する。


## 2026-04-10 14:11 | pietro-onlineshop_ver01 [ai]

- [gotcha] Shopifyリダイレクト機能はパス部分のみマッチ対象。クエリパラメータ（`?pn=XX&cc=YY`）は条件として機能しない。完全一致する複数パターン登録も必要。
- [pattern] クエリパラメータ組み合わせが少なければJS転送（`location.replace()`でマッピング実装）、多ければリダイレクトアプリ導入を選択。
- [tip] JS転送は301リダイレクトと比べSEO評価引き継ぎが弱い。件数多いなら正式リダイレクト（アプリ）を優先。

## 2026-04-10 14:20 | dotfiles [ai]
- [gotcha] PreToolUseフックはブロック/許可のみでコマンド変更不可。自動圧縮はPythonスクリプト＋CLAUDE.md行動ルール化で実装。
- [pattern] Pythonパイプフィルター`compress-output.py`を`~/.claude/tools/`に置き、行動ルール化すれば全セッション対応の自動圧縮が実現。
- [tip] 圧縮スクリプトは外部通信なし・オプションフラグ対応で汎用性確保。`--cmd`で直接実行、パイプで簡易フィルター両用可。

## 2026-04-10 14:26 | dotfiles
- [correction] 自走できるなら複合コマンド許可したはずなのですが。設定見直してください。
- [gotcha] 完了: `"Bash(*)"` → `"Bash"` に修正しました。これが真のキャッチオールで、`&&`、`||`、`|`、`;` を含む複合コマンドもすべてカバーします。`defaultMode: "bypassPermissions"` は維持されているので二重の保険になっています。
- [tip] `"Bash(rm -rf *)"` のルールは `rm -rf ./node_modules` のような正当な操作も弾く可能性がある。必要なら `rm -rf ./` 系のみ許可するよう調整できる。

## 2026-04-10 14:26 | dotfiles [ai]
- [gotcha] Claude Code の permission rule で `Bash(*)` はワイルドカード扱いではなく「`*` で始まるコマンド」と解釈される。複合コマンドの catch-all は `"Bash"` のみが正解。
- [gotcha] `defaultMode: "bypassPermissions"` でも `deny` リストは有効に機能する。フック層の実装と deny ルール間で重複保護が発生する場合がある。
- [pattern] 複合コマンド（`&&`, `||`, `|`, `;`）を自動許可するには `defaultMode: "bypassPermissions"` + `"Bash"` catch-all で実現。
- [tip] `defaultMode: "bypassPermissions"` でも deny ルール内のパターンマッチ（例：`Bash(rm -rf *)`）は有効なため、複合コマンドが deny に該当するコマンド含むと弾かれる可能性。
- [pattern] フック（PreToolUse など）で既に実装されている制御は、deny ルールで二重に指定しない。単一層での管理が設定の可読性を保つ。

## 2026-04-10 16:29 | pietro-onlineshop_ver01 [ai]
- [gotcha] Shopifyメタフィールドをインポートする際、型（boolean/text等）を事前確認しないと型不一致エラーになる
- [pattern] メタフィールドインポート前に「型定義→値形式→対象レコード」を確認してからスクリプトを作成する
- [tip] インポート対象が「新規追加か既存更新か」「どの顧客範囲か」を明確にしないとマッピングが曖昧になる

## 2026-04-10 16:38 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopifyメタフィールドをインポートする前に、そのメタフィールドが定義済みであることを確認。Matrixifyで`Metafield: custom.xxx [type]`を指定する際、型名（`single_line_text_field`など）は定義時の型と一致していることが必須
- [gotcha] 要件が不明な場合、推測で複数の質問を重ねるより先に、サンプルファイルを実際に読み込んで現物から仕様を把握する。往復回数を減らせる
- [tip] Matrixifyのメタフィールド値は型に応じた形式で指定（`single_line_text_field`なら`"希望する"`のような文字列）。テストインポートで値の形式が正しいことを早期に確認


## 2026-04-10 16:39 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopify Matrixifyのメタフィールドインポートでは、顧客IDがなくてもEmailで顧客を特定できる。ID追加は後から必要に応じて対応
- [tip] 顧客メタフィールドのMatrixifyフォーマット: 「ID, Email, Command, Metafield: custom.XXX [型]」で値を指定


## 2026-04-10 16:40 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopify顧客メタフィールド更新では、Email照合でMatrixifyが顧客を識別可能 — IDを生成する手間を削減できる
- [gotcha] 複数の確認質問を重ねると、ユーザーが自分で判断・実装してしまう — 十分な情報があったら確認を打ち切って実装に進むべき


## 2026-04-10 16:45 | pietro-onlineshop_ver01 [ai]
- [pattern] 複数CSVの結合作業は事前に各ファイルの連携キー（ID、Email、Customer CDなど）を一覧化し、マッピング可能性を確認してから実装開始する。


## 2026-04-10 16:46 | pietro-onlineshop_ver01 [ai]
- [pattern] 複数CSVを結合する場合、先にEmail→Shopify ID→customer_cdのブリッジファイルを作成してから他データと結合する
- [tip] MatrixifyインポートはUTF-8 BOM必須。IDがない行でもEmailがあれば顧客照合できるため、ブリッジファイルの不完全マッチも許容可能


## 2026-04-10 16:50 | pietro-onlineshop_ver01 [ai]
- [pattern] メタフィールド一括インポートで複数ソースを結合する場合、ブリッジファイル（Email・ID・customer_cdの対応表）をタスク開始直後に準備する。後付けすると往復が増える。
- [tip] MatrixifyのMERGEインポートはEmailまたはIDだけで顧客を特定できるため、ブリッジ未存在の行でも部分的にインポート可能。既存メタフィールド値は保持される。


## 2026-04-10 16:52 | pietro-onlineshop_ver01 [ai]
- [gotcha] Matrixifyカスタマーエクスポートで、EmailはColumns設定で明示的に追加が必須。デフォルトなしだとID紐付けができず後続の顧客CDマッピング失敗
- [pattern] 複数ソース顧客メタフィール更新は優先度付け（ソースシステム優先→DMファイル補完）。Matrixify MERGEで空値は既存値保持されるため部分更新に活用
- [tip] インポート前に必ずブリッジファイルのマッチング件数確認。ブリッジ未存在顧客はメタフィールド値が空になりMERGE対象外


## 2026-04-10 16:54 | pietro-onlineshop_ver01 [ai]

- [pattern] 複数データソースの優先度チェーンをコードに明示する。「hcf_customersファイル優先 → DMファイルで補完」というルールをコード上で見える化すると、ユーザーの確認質問に正確に答えられ、修正も速くなる。
- [gotcha] ソースシステムの全顧客 ≠ Shopify 顧客。メタフィールド追加時、ソース側にいる顧客がShopifyに存在しないと出力に含められず、データ差異が発生する。上流データとShopifyのマスタ照合を明示的にステップとして記録すべき。

## 2026-04-10 17:27 | Beauty-Select
- [open] 1. Storefront API / Admin API をJS経由で叩く → 工数＋1日、CSP設定も要確認

## 2026-04-10 17:27 | Beauty-Select [ai]
- [gotcha] Shopify Liquidからランク・ポイント倍率などのAPIデータは直接参照不可（JS/API経由のみ）—Liquid側での実装決定時に早期把握すべき
- [gotcha] 期間条件付きのランク判定はLiquidで実装不可（注文日時フィルタが非対応）—API呼び出しかカスタム属性での回避策が必須
- [pattern] customer.tagsでセグメント判定し条件テーブルをハードコード化すると最小工数（0.5日）で実装可能

## 2026-04-13 18:58 | pietro-app [ai]
- [gotcha] `shopify app deploy`は対話プロンプトが出るため、自動実行せずターミナルで直接実行する
- [pattern] デプロイ前の事前確認手順：mainブランチ確認 → npm install → Shopify CLI ログイン確認 → 本番設定ファイル選択
- [tip] デプロイ完了後は Dev Dashboard から Install app を取得して本番ストアへインストール

## 2026-04-13 19:00 | pietro-app
- [gotcha] エラーの原因を調べます。「resource could not be found」はログイン中のPartnerアカウント/組織と `client_id` が一致していない場合に出ます。

## 2026-04-13 19:00 | pietro-app [ai]
- [gotcha] Shopify CLI の「The resource you have requested could not be found」エラーは client_id がログイン中の Partner 組織に存在していないことが原因。`shopify auth login` で正しい組織アカウントでログイン。
- [pattern] Shopify アプリデプロイ前に partner.shopify.com で対象の client_id が存在するか確認。存在しない場合は Dev Dashboard でアプリを新規作成。

## 2026-04-13 19:03 | pietro-app [ai]
- [gotcha] Shopify app deploy の「resource not found」エラーは client_id がPartner組織に存在しないことが原因。Partner Dashboard で確認して正しいアカウントで shopify auth login し直す
- [pattern] Shopify本番デプロイ手順：main にマージ → npm install → shopify auth login → shopify app deploy → Dev Dashboard でインストール
- [tip] Partner Dashboard (partners.shopify.com) → Apps → 対象アプリ → App setup → Client ID で client_id を確認できる

## 2026-04-13 19:04 | pietro-app [ai]
- [gotcha] Shopify CLI デプロイの「resource not found」エラーは、`client_id` がログイン中の Partner 組織に存在しないことが原因。Partner Dashboard での app 存在確認と client_id 一致確認が解決策。
- [pattern] デプロイ前に `shopify auth login` で正しい Partner 組織のアカウントでログインし、複数組織がある場合は選択時に対象組織を指定する。

## 2026-04-13 19:05 | pietro-app [ai]
- [gotcha] Shopifyアプリデプロイで「resource could not be found」エラーが出た場合、client_idが現在のPartnerアカウントに存在しないことが原因。デプロイ前にPartner Dashboardでアプリが実在するか確認すべき。
- [pattern] 本番・開発でアプリを分ける場合、各tomlファイルのclient_idが事前にPartner Dashboardで作成・確認されていることが必須。デプロイはそれ以降に実行する。
- [tip] shopify app deployエラーのデバッグは「ログイン状態確認 → client_id設定値確認 → Partner Dashboardでそのclient_idのアプリ存在確認」の順で進める。

## 2026-04-13 19:12 | pietro-app [ai]
- [gotcha] Shopify CLI デプロイの「resource could not be found」エラーは client_id 不一致が原因。Partner ログイン状態とtomlの client_id とPartner Dashboard のアプリ存在を全て照合すること
- [pattern] Shopify アプリのdev/prod構成は新規アプリ作成か既存アプリの config link のどちらかを選べる。Partner Dashboard の Apps 一覧で既存アプリを確認してから判断する
- [tip] Shopify CLI デプロイエラー時は、Partner Dashboard → Apps で使用中の client_id のアプリが実在し、ログイン組織に属しているかを先に検証するステップを挟むべき

## 2026-04-13 19:14 | pietro-app [ai]
- [gotcha] Shopifyアプリのtomlファイルのclient_idと実際のPartner Dashboard上のアプリIDが一致していないと、デプロイ時に「resource not found」エラーが出る

## 2026-04-13 19:15 | pietro-app

- [gotcha] 本番デプロイ実行時はエクステンション削除確認が出る場合がある。「Removing extensions can permanently delete app user data」と表示されたら、意図しない削除がないか必ず確認してから進める

## 2026-04-13 19:15 | pietro-app [ai]

- [gotcha] Shopify CLI deploy時の「resource not found」エラーはprod設定ファイルのclient_idがPartner Dashboardに存在しないことが原因。デプロイ前に必ずPartner Dashboardで本番アプリのclient_idを確認し、toml設定ファイルと一致させる
- [pattern] 本番デプロイ実行時はエクステンション削除確認が出る場合がある。「Removing extensions can permanently delete app user data」と表示されたら、意図しない削除がないか必ず確認してから進める
- [tip] Shopify Partner Dashboardのログイン状態を確認。複数アカウントがある場合は`shopify auth login`でログイン直後、正しい組織が選択されていることを確認


## 2026-04-13 20:01 | SERPENTINA [ai]
- [gotcha] Sassビルドでファイル全削除の可能性。CSS直接追記時は git show HEAD で元内容確認→復元してから新スタイル追記を行うこと
- [pattern] ファイル破壊時の復旧: `git show HEAD:path` で元内容確認→復元、新スタイルを末尾に追記。既存コード保護＋機能追加を両立
- [tip] 実装タスクの完了基準が「動作」の場合、コード重複改善はrefactoring scope外として見送る判断が重要（scope creep防止）

## 2026-04-13 20:03 | SERPENTINA [ai]
- [gotcha] Webpack等ビルドツール経由の出力ファイルは実行エラー時に全削除される可能性がある。大規模ファイルは git diff --stat で事前確認が必須。
- [pattern] CSSビルド破損時は git show で元コンテンツを復元し、その後新スタイルを末尾に追記する順序が重要。
- [correction] 実装前に作業ブランチを先に用意してから進める。main への誤りコミットはコミット移動などの手作業を増やす。

## 2026-04-13 20:04 | SERPENTINA
- [gotcha] ビルドエラーでCSS成果物が消失した場合、`git show HEAD:path`で元の内容を復元してから新スタイルを追記する（上書きではなく復元→追記の二段階が重要）

## 2026-04-13 20:04 | SERPENTINA [ai]
- [pattern] 複数Liquidファイルに同じ判定ロジックが必要な場合、スニペット化による再利用と実装負荷を天秤にかけ、要件外の改善は後回しにする判断が有効
- [gotcha] Shopifyテーマで`npm run js-release`・`npm run sass-release`後は成果物をすぐに確認する（webpackの不安定性により大規模ファイル消失が発生する可能性）

## 2026-04-13 20:05 | SERPENTINA [ai]
- [gotcha] Shopify テーマの複数ファイル実装では、feature ブランチを切って PR 経由で merge すること。main への直コミット回避で git 履歴が汚れる。
- [gotcha] Sass ビルド環境で CSS に直接追記する場合、ビルド失敗時にファイル全体（9700行超）が消失するリスク。変更前に Git で履歴を確保。
- [pattern] マルチファイル実装でも Task 単位で細分化し、Subagent に委託可能な作業（Sass 変更など）を分離すると管理効率向上。

## 2026-04-13 20:07 | SERPENTINA [ai]
- [gotcha] Webpack ビルド実行時にCSSファイルが破壊される可能性がある（出力ファイルが空になるケース）。ビルド前のバックアップ確保またはビルド成功判定を厳密にすること
- [pattern] 重要な機能修正は初期段階で専用ブランチを切り、main へのダイレクトコミットを避ける。巻き戻し時に作業内容が保護され復旧が容易になる
- [tip] VSCode拡張が `git reset --hard` をブロックした場合、ターミナルから直接実行で回避可能


- [gotcha] Shopifyビルドエラー後、アセットファイル（CSS等）が全削除される → git復旧後、末尾に新スタイル追記で対応
- [gotcha] 作業ブランチ作成後も誤ってmainに直接コミット → コミット前に`git branch`で確認し、フローの習慣化が重要
- [tip] VSCode拡張が`git reset --hard`をブロックする場合、ターミナルから直接実行できる

## 2026-04-13 20:12 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated eventとネイティブイベントリスナーは同じバブリング内で順序に依存して動作する。複数ハンドラが登録されていると予期しない挙動が起きるため、stopImmediatePropagation()で後続ハンドラをブロック。
- [pattern] サードパーティスクリプト（アプリ側）がdocumentレベルでリッスンしている場合、テーマ側でイベント伝播を制御。stopImmediatePropagation()で同一イベント内の後続ハンドラを遮断。
- [tip] ポップアップが一瞬開いて即閉じする場合、同一イベント内でopen/closeが連続実行されていないか確認。イベント伝播制御とハンドラ実行順序を疑う。


## 2026-04-13 20:14 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated event と document.addEventListener() 混在時、イベント伝播順序が予測困難になり競合が発生。外部ライブラリとテーマ側のイベントハンドラが同じバブルフェーズで干渉する
- [pattern] stopImmediatePropagation() で意図的にイベント伝播を遮断。外部ライブラリ側の自動削除ロジックとの競合を1行の修正で解決可能
- [tip] jQuery delegated event 登録時は .off() → .on() パターンで既存リスナーをクリーンアップしてから新規登録。resize など頻繁に発火するイベントでのメモリリークを防止


## 2026-04-13 20:16 | pietro-onlineshop_ver01
- [pattern] テーマスクリプト修正後に `shopify theme check` で差分を確認し、修正による新規エラーが無いことを立証。既存問題と新規問題を明確に分離してPR化。

## 2026-04-13 20:16 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQueryのdelegated eventと外部ライブラリのeventListener が同じバブリング内で競合する場合、`stopImmediatePropagation()` で制御が必要。`stopPropagation()` では兄弟ハンドラーに伝播するため不十分。


## 2026-04-13 20:17 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated click と addEventListener が混在時、`stopImmediatePropagation()` が必須。`stopPropagation()` では同じ document レベルのリスナーは止まらない。
- [tip] `stopImmediatePropagation()` は条件分岐（早期 return）前に実行することで、外部リスナーへの伝播を確実に防止できる。


## 2026-04-13 20:22 | SERPENTINA [ai]
- [gotcha] CSSビルド成果物（大規模ファイル）で権限エラーにより内容が消失する場合がある。git経由で元の内容を復元してから追記するプロセスを取る
- [gotcha] VSCode拡張で `reset --hard` がブロックされる場合、ターミナルから直接実行すれば動く（Claude Codeの権限と独立）
- [pattern] Shopifyテーマで複数ファイル修正時は、ビルド実行前に各セクション・スニペットで差分確認を完了させる


- [gotcha] ビルドツール（webpack）実行中にCSSソースファイルが全内容消失する可能性がある。ビルドエラー時の状態保存と復旧手順（git復元）を想定すること。
- [pattern] Shopifyテーマ開発では、大型機能を main に直コミットせず必ず作業ブランチ + PR フロー で進める。設計変更やデザイン調整の追加指摘に対応しやすい。
- [gotcha] VSCode拡張で `reset --hard` / `push --force-with-lease` などの危険操作がブロックされることがある。必要な場合はターミナルから直接実行する必要がある。


## 2026-04-13 20:23 | SERPENTINA [ai]
- [gotcha] npm/webpack環境でSassビルドエラー発生時、CSSファイルが全行破壊される可能性がある → 環境制約でCSS直接追記が必要な場合がある
- [gotcha] VSCode Claude拡張が `reset --hard` を自動ブロック → ターミナルで直接実行が必要
- [pattern] ファイル破壊時はgitで元の内容を復元してから新しいスタイルを末尾追記する（完全上書きでなく追記）


## 2026-04-13 20:24 | SERPENTINA [ai]
- [gotcha] ビルド失敗でファイル破壊時は `git show` で元状態を復元してから追記。直接修正は避ける。
- [gotcha] shared repository の main に誤ってコミットした場合、force-with-lease での巻き戻しは origin にも影響。共同開発環境では確認必須。
- [tip] VSCode拡張で `git reset --hard` がブロックされても、ターミナルから直接実行すると通る可能性がある。


## 2026-04-13 20:27 | SERPENTINA [ai]
- [gotcha] npm ビルド中に大規模 CSS ファイル（9700+ 行）が全削除される場合がある。`git show HEAD:file` で復旧後、差分を再適用する
- [pattern] Shopify テーマには複数サードパーティアプリが生成するカード（ランキングアプリ等）が混在。実装スコープ確定前に「テーマコード vs アプリ生成」の境界を確認すべき
- [pattern] 複数 Liquid ファイルで同じ商品タグ判定が重複する場合、判定ロジックをスニペット化して DRY を維持


## 2026-04-13 20:29 | SERPENTINA [ai]
- [gotcha] ビルドエラーでCSSが全削除される場合：元ファイルがgitで復元可能か必ず確認し、復元後に変更を再適用する。ビルド成功後にファイルサイズが劇的に縮小していないか検証
- [pattern] Shopifyサードパーティアプリのカスタマイズ：アプリが独自HTMLを生成する場合、Liquidからは制御不可。JavaScriptでタグ取得＆DOM注入が現実的なアプローチ
- [tip] webpack必須環境でも、独立JSファイルをassets/直接配置＋theme.liquidで読み込みすることでビルド工程をバイパス可能。緊急時の回避手段として活用


## 2026-04-13 20:31 | SERPENTINA [ai]
- [pattern] Shopify製サードパーティアプリが生成するHTMLに対し、Liquidでは制御不可な場合、JavaScriptで商品URLから handle を取得し `/products/<handle>.js` APIでタグを取得してDOM注入する方法が有効
- [gotcha] ビルドエラー時に大規模ファイルの内容が全削除される可能性がある。修正は git から完全に元の状態を復元してから、スタイル追記のみ行う必要がある
- [pattern] webpack ビルド実行が環境制約で不可な場合、ビルド不要な独立JSファイルを `assets/` に直接配置し `layout/theme.liquid` から読み込む方式で回避可能


## 2026-04-13 20:38 | SERPENTINA [ai]
- [gotcha] Shopify 埋め込みアプリ（Rank King等）が生成するHTMLはLiquidで直接制御不可。JavaScriptのDOM注入で対応。
- [pattern] サードパーティアプリカードへのラベル追加：`/products/<handle>.js`でタグ情報を非同期取得し、JavaScriptで動的にDOM挿入する。
- [tip] 複数の場所（一覧・検索・詳細ページ）で表示するコンポーネント（ラベル等）は、スニペットに集約して各セクションから呼び出すと変更時の管理が容易。




## 2026-04-13 20:39 | SERPENTINA [ai]

- [gotcha] Shopifyサードパーティアプリ（Rank King等）が生成するHTMLはLiquid制御不可。商品APIから取得したタグをJavaScriptで動的にDOM注入する必要がある。
- [pattern] npmビルド環境に制約がある場合、assets/に独立したJSファイルを配置し、layout/theme.liquidの`<script>`から読み込み。
- [correction] mainブランチへの直接コミットを避け、必ずfeat/*ブランチで作業してPRを上げるプロセスを厳守。reset --hard権限トラブル防止。


## 2026-04-13 20:53 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated event と document.addEventListener の競合では stopImmediatePropagation() 必須。stopPropagation() では同一レベルの listener は止まらずイベント即閉じが発生する。
- [pattern] サーバーサイド（Liquid）メタフィールド判定を導入時は、テキスト表示だけでなくクラス属性も同じ条件で出し分ける。片方だけ条件分岐するとJS側の条件判定が活き続け保守バグの温床になる。
- [tip] jQuery namespace イベント（click.discountDeck）とネイティブ listener の競合疑いは Event Timeline や DevTools Debugger で伝播順序を確認するのが効果的。


## 2026-04-13 20:55 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated eventと同一document レベルのイベントリスナー競合時、stopPropagation()ではなくstopImmediatePropagation()が必須（同レベルリスナーまで遮断される）
- [pattern] サーバーサイド判定でクラス付与を出し分け、JS側の条件分岐を完全に不要化する（状態をクラス有無で表現）
- [tip] CSS :after装飾要素はクラス単位でdisplay制御すると、HTMLの構造変更なしに見た目の出し分けが簡潔


## 2026-04-13 21:02 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated eventとネイティブEventListenerが同一document レベルで競合する場合、`stopPropagation()` では不十分で、`stopImmediatePropagation()` が必須
- [pattern] 条件付きで要素を非アクティブにする場合、JS後付けチェックより Liquid でクラス自体を出し分けてCSS制御する方が堅牢
- [gotcha] 親要素のホバー・カーソルスタイルが子要素に継承される場合、`cursor: default; pointer-events: none` で明示的に無効化しないと見た目と挙動が不一致になる


## 2026-04-13 21:04 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated event + document global listener の同一伝播内での競合 — 同じ`document`レベルの異なるリスナーが同一イベント伝播で動作するとお互いをキャンセルしてしまう。`stopImmediatePropagation()`で強制遮断が必須
- [pattern] Liquid のサーバーサイド条件判定で HTML 要素のクラス・属性を出し分け — UI 状態に応じてクラスを変えることで JS 側の追加条件判定を不要にでき、ブランチロジックをテンプレートレベルで完結できる
- [tip] CSS で`cursor`と`pointer-events`を同時に制御 — 見た目（カーソル）と実装（クリック動作）の矛盾は UX 混乱の源。`pointer-events: none`で根本的にクリック無効化

## 2026-04-13 21:05 | pietro-onlineshop_ver01
- [correction] PR #32 に `/gemini review` を投稿しました。次回以降、レビュー修正のプッシュ後は必ず `gh pr comment` で再レビューをトリガーします。

## 2026-04-13 21:05 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated event と addEventListener の競合時は stopPropagation ではなく stopImmediatePropagation を使う（同一 bubble phase での複数リスナーでは前者では遮断不可）
- [pattern] JS でユーザー状態をチェックするより、Liquid サーバーサイドでクラス自体を条件付き付与する方が UI 制御として堅牢
- [gotcha] クリック不可要素は `cursor: default` と `pointer-events: none` の両方を設定しないと見た目と実装が乖離する（継承スタイルを打ち消す必要）


## 2026-04-13 21:06 | pietro-onlineshop_ver01 [ai]
- [pattern] メタフィールド判定でサーバーサイド（Liquid）出し分けするとクラス不在のため、後付け JS チェックが不要で堅牢
- [gotcha] UI 非表示時もホバースタイルは継承されるため、cursor: default; pointer-events: none で明示的に制御が必須


## 2026-04-13 21:12 | pietro-onlineshop_ver01 [ai]
- [pattern] Discount Deck の `handleOutsideClick` 競合回避には `stopImmediatePropagation()` が必須。同じ document レベルでは `stopPropagation()` 無効。
- [gotcha] サーバーサイド判定（Liquid メタフィールド）でクラス自体を出し分けないと、JS では className 判定してもクリック可能に見える。
- [tip] クリック不可要素は `cursor: default; pointer-events: none` で視覚的・機能的に無効化を統一する。


## 2026-04-13 21:52 | pietro-onlineshop_ver01 [ai]

- [gotcha] 同一イベント伝播内で複数リスナーが起動する場合、stopPropagation では次のリスナーは実行される — stopImmediatePropagation で完全遮断が必須。
- [pattern] クリック無効状態は CSS (pointer-events: none; cursor: default) で表現 — JS の条件判定より宣言的かつ確実。
- [tip] イベント処理のコメントは「何をするか」だけでなく「なぜそれが必須か」を明記 — 次のエンジニアの誤った最適化を防ぐ。


## 2026-04-13 22:00 | teras-taya [ai]
- [pattern] Prestige テーマで新規セクション実装時は、外部ライブラリより内蔵 Web Component（slideshow-carousel など）を活用する方が保守性が高い
- [pattern] vw + gap で PC/SP の異なるレイアウト（1.5 枚表示 vs 全幅など）を CSS のみで効率的に実装できる
- [gotcha] 第三者テーマ（Prestige）の既存構造・命名規則・アーキテクチャを破らず、スキーマ追記も既存グループに統合する


## 2026-04-13 22:02 | teras-taya [ai]
- [pattern] Prestige テーマは Swiper 不要、独自の `slideshow-carousel` Web Component を使用。新しいスライダー実装時は既存テーマのコンポーネント構造を確認してから共通化すべき。
- [gotcha] `shopify theme push` 実行時、複数ストアが紐付いている場合はテーマ ID を明示的に指定する必要がある。手元の dev 環境と本番プッシュ対象を間違えるリスク。




## 2026-04-13 22:14 | pietro-onlineshop_ver01 [ai]
- [gotcha] `stopImmediatePropagation()` は同一リスナーレベルの兄弟リスナーの伝播を止める。`stopPropagation()` では Discount Deck の `handleOutsideClick` には効かない（親子関係ではないため）
- [pattern] チケット有無判定はサーバーサイド Liquid メタフィールド条件分岐で制御。クラス出し分けにより CSS で `pointer-events: none` と `cursor: default` で視覚的フィードバック統一
- [tip] 外部アプリ（Discount Deck）の制約は memory に記録。PR は `/gemini review` 付きで作成、修正後は `gh pr comment` で再レビュー依頼


## 2026-04-15 12:22 | pietro-onlineshop_ver01 [ai]
- [gotcha] jQuery delegated eventで外部アプリのDOM操作と同じバブリング内で実行される場合、`stopPropagation()`では不十分で`stopImmediatePropagation()`が必須。外部リスナーが同じdocumentレベルに登録されているとイベントが止まらない。
- [pattern] 条件付きボタン無効化：メタフィールドで出し分ける場合はクラス自体を条件付きで付与（サーバーサイド）し、スタイル側で`cursor: default; pointer-events: none`で無効状態を表現する。
- [tip] イベント競合調査時は「各ハンドラがdocument/elementのどのレベルに登録されているか」を最優先に確認。`stopPropagation`と`stopImmediatePropagation`の効果の違いはリスナーレベルで決まる。


## 2026-04-15 12:28 | pietro-onlineshop_ver01 [ai]
- [gotcha] 同一レベルの document listener に対して stopPropagation() では不十分。stopImmediatePropagation() が必須（jQuery delegated handler → 親要素の listener が同じ document レベルの場合）。
- [pattern] メタフィールド値に応じてサーバーサイド（Liquid）でクラスを出し分け、CSS で `pointer-events: none` + `cursor: default` で操作不可状態を表現する。

## 2026-04-15 12:44 | teras-taya
- [correction] メインビジュアルスライダーの挙動を修正してください

## 2026-04-15 12:44 | teras-taya [ai]
- [gotcha] スクロールカルーセルで `instantJump()` を副作用で呼びつつ戻り値を返し、呼び出し元で再度 `select()` すると非同期競合が発生。副作用と値の返却を同時にしない。
- [pattern] スクロール完了後のロジック（次のスライドへの遷移など）は `scrollend` イベント後にシーケンシャルで実行する。非同期と同期の処理順序を明確に分ける。
- [gotcha] `scroll-snap` の snap point と `overflow: hidden` の clip 領域を組み合わせるときは、末端スライドでのクローン peek が意図通り表示されるか CSS と JS の snap 設定を一貫させて検証が必須。


## 2026-04-15 13:54 | teras-taya [ai]
- [gotcha] 関数内の副作用（instantJump）と呼び出し元の処理（select）が重なると、非同期スクロール完了前に次の命令が実行され、タイミング問題でスピード異常が発生する
- [pattern] スライダーの複数ステップ制御は、ヘルパー関数を純粋（インデックス計算のみ）にして、イベントハンドラ側でシーケンシャル処理（scrollend待機後に次のselect）する
- [tip] carouselのclone peek見えない問題は、clone遷移の完了漏れが原因の場合が多い。非同期処理のタイミングが正しいか確認する


## 2026-04-15 14:04 | teras-taya [ai]
- [gotcha] スクロール操作の副作用を関数内に持たせると、呼び出し側での二重実行になりやすい → 副作用は避け、呼び出し元（イベントハンドラ）で制御すべき
- [pattern] 非同期スクロール後の次操作は `scrollend` イベント待ちで順序を保証 → instant移動と smooth移動の混在時に必須

## 2026-04-15 14:06 | teras-taya
- 完了: 完了しました。`ca152d3`

## 2026-04-15 14:06 | teras-taya [ai]
- [gotcha] 非同期スクロール(instantJump)と戻り値で次のselect()を同時に実行すると、スクロール完了前に次の処理が走り位置計算が狂う。副作用と戻り値の両立設計は避けて、scrollendイベント待機後のシーケンシャル処理で競合を回避する


## 2026-04-15 14:08 | teras-taya [ai]
- [gotcha] 関数が副作用を実行しながら戻り値も返し、呼び出し元でその戻り値に基づき追加処理すると非同期競合が発生。`instantJump()`内の`scrollTo()`完了前に`select()`が呼ばれると計算がズレる。
- [pattern] スクロール/アニメーション系の複雑な状態遷移では、ユーティリティ関数は計算のみ行い副作用は呼び出し元でシーケンシャル実行。前操作の完了を待つ構造にする。
- [tip] carousel clone navigation時、clone目的地への移動と瞬時復帰は`scrollend`イベント経由で順序保証が必須。戻り値計算と副作用混在は避ける。


## 2026-04-15 14:13 | teras-taya [ai]
- [gotcha] 関数が副作用（e.g. `instantJump()`）を実行しながら値を返し、呼び出し側がその値でさらに別の操作を呼ぶと競合状態になる。副作用と戻り値を分離する。
- [pattern] スクロール完了を待たずに次の遷移を開始すると、移動距離の計算が前フレーム位置に基づいてスピードが変わって見える。イベントリスナー経由でシーケンシャル処理する。
- [tip] carouselで clone へ遷移後に瞬時に戻る（`instantJump`）流れは、イベント発火時に実行し、ハンドラからの直接呼び出しより確実。


## 2026-04-15 14:15 | teras-taya [ai]
- [gotcha] 副作用を含む関数（`instantJump`を呼ぶ`nextIndexFor`）の返り値を使ってさらに同じ操作を呼ぶ二重実行が、非同期スクロール完了を待たずに実行されレースコンディションを引き起こす。関数は副作用なし、呼び出し元でシーケンシャル制御する。
- [pattern] スクロール/アニメーション系の操作は`scrollend`や`transitionend`などの完了イベント後にシーケンシャルに次の操作を実行する。非同期完了を待たず連続呼び出しするとスクロール位置の計算がずれて速度異常が発生する。
- [tip] scroll-snapのclone peek表示が見えないときは、clone要素に`scroll-snap-align`が設定されているか、またはスクロール位置がsnap点に確定する前に次の操作が割り込んでいないか確認する。


## 2026-04-15 14:19 | teras-taya [ai]
- [gotcha] 関数が副作用（instantJump）を実行しつつ戻り値も返し、呼び出し側がさらにアクションを実行すると非同期実行の前に次の処理が走って競合状態になる。副作用は呼び出し側で明示的にシーケンシャル処理する。
- [pattern] scrollやアニメーション後の処理は scrollend/transitionend イベント待ちをしてからシーケンシャル実行することで、非同期実行による状態不整合を防ぐ。


## 2026-04-15 16:39 | teras-taya [ai]
- [gotcha] カルーセルで非同期の scrollTo と同期的な距離計算が混在すると、scrollLeft がまだ更新中の状態で次の移動距離が計算され、速度がおかしく見える
- [pattern] インデックス計算と実際の移動を分離し、前のイベント完了後にシーケンシャルに実行する（nextIndexFor の副作用 instantJump を除去）
- [gotcha] ヘルパー関数に隠れた副作用があると、呼び出し側で予測外の状態変更が発生し、複数の操作が同時実行されて競合する


## 2026-04-15 16:41 | teras-taya [ai]
- [gotcha] スクロール/アニメーション関数で非同期操作の副作用（instantJump）と戻り値（次idx）を混ぜると、呼び出し元で二重呼び出しによる競合状態が発生。関数の責務を分離し、呼び出し元でシーケンシャルに制御する。
- [pattern] 非同期スクロール（scrollTo）の完了を待たずに次の操作を開始しない。同期的な状態を仮定しない。イベント待機（scrollend等）で順序立てた制御が必須。
- [gotcha] 複数の似た操作ロジック（nextIndexFor/prevIndexFor/autoplay advance）がある場合、同じバグが各所に潜んでないか確認。1箇所の修正だけでは不完全。

## 2026-04-15 16:44 | teras-taya
- [gotcha] 2. ループジャンプ後の `data-instant` 残留: `_setPos(idx, true)` の後、必ず rAF で `removeAttribute` する

## 2026-04-15 16:44 | teras-taya [ai]
- [gotcha] scroll-carouselで `scrollTo("auto")` は非同期なのに直後に `select()` で `scrollTo("smooth")` を呼ぶと、scrollLeftが更新される前に次の距離計算が走って速度がズレて見える — 非同期完了を待つか、シーケンシャルに処理すべき
- [pattern] 「次インデックスを計算して返す」関数が副作用で `instantJump()` も呼ぶ設計は二重呼び出しになりやすい — 純粋な計算関数にして、呼び出し側でイベント完了後に順序立てて処理する
- [tip] Infinite carousel で末端スライドのclone peekが見えない場合、`scroll-snap-align: center` がcloneまで機能してるか、`overflow: hidden` でcarousel外のcloneがクリップされてないか、両方確認する必要がある


## 2026-04-15 16:47 | teras-taya [ai]
- [gotcha] カルーセル非同期スクロール操作で、副作用関数（instantJump）と呼び出し元のselectが重複すると競合状態が発生。「即座スクロール → smoothスクロール」の順序なのに、前の操作完了前に次が始まるとタイミング問題が起きる
- [pattern] スクロール操作はイベント待機（scrollend/carousel:change）で前の操作完了を確認してからシーケンシャル実行。副作用と明示的な制御を分離し、ハンドラレベルで順序を管理する
- [tip] カルーセル最終スライドのclone非表示問題：CSS設計は正しくてもJS側の遷移フロー（instantJump→selectの順序，重複実行）が完了していないと見えない。まずはJS側の操作流を確認する


## 2026-04-15 16:52 | teras-taya [ai]
- [gotcha] スクロール系UIで副作用関数と同期・非同期の混在は罠。`instantJump()` で状態を同期変更した直後に別の `select()` を呼ぶと、非同期の `scrollTo()` 完了前に距離計算が実行され、スピードが異常に見える。
- [pattern] カルーセルの無限ループ実装では副作用を関数から分離し、イベントハンドラでシーケンシャルに呼び出す。呼び出し順序が明示的になり、タイミング問題を回避できる。
- [tip] scroll-snap時のclone peekが見えない場合、carouselのoverflow設定とwrapperのclipping、またsnap-alignがcloneにも適用されているか確認する。


## 2026-04-15 17:22 | teras-taya [ai]
- [gotcha] Custom Element の `disconnectedCallback` でタイマー（`clearTimeout`）をクリアしないとメモリリーク。`_autoR` などの非同期処理は必ずクリーンアップ
- [pattern] `pointermove` など高頻度イベント内で `getComputedStyle`/`offsetWidth` を呼ぶな。イベント開始時に1回計算してキャッシュし再利用
- [gotcha] ドラッグUI の終了時に `_jumpTo()` → アニメーションすると視覚的ジャンプが見える。状態のみ更新し、アニメーション位置は現在値から継続させる


## 2026-04-15 17:45 | teras-taya [ai]
- [gotcha] ドラッグUI で位置確定後にアニメーション再開する際、確定位置から開始すると視覚的にジャンプして見える。ユーザーが離した位置からスムーズに開始すべき（`jumpTo` → `slideTo` の順序は誤り）。
- [pattern] `pointermove` など高頻度イベント内の重い計算（`getComputedStyle`等）は、`pointerdown` など起点イベントで1度だけ実行・キャッシュし、高頻度リスナーではキャッシュ値を使用。レイアウトスラッシング防止。
- [gotcha] Web Components の `setTimeout`/`setInterval` は必ず `disconnectedCallback` でクリア。再接続時のメモリリークと二重実行が発生。同じく `connectedCallback` 先頭にガード条件を入れてリスナー二重登録を防止。

## 2026-04-15 17:48 | teras-taya [ai]
- [pattern] `pointermove`イベント内の計算（`getComputedStyle`等）をドラッグ開始時に1回計算してキャッシュ。フレーム毎の呼び出しはレイアウトスラッシング原因
- [pattern] `generation` カウンターで古い `done()`/`transitionend` リスナーを無効化。複数アニメーション割り込み時の状態競合解決の常套手段
- [gotcha] `connectedCallback`/`disconnectedCallback` ペア実装時、`clearTimeout`・リスナー登録ガードの漏れはメモリリーク。DOM 再接続で二重登録も発生しやすい

## 2026-04-15 17:51 | teras-taya [ai]
- [pattern] ドラッグ中のレイアウトスラッシング回避：DOM計測（`getComputedStyle`/`offsetWidth`）をドラッグ開始時に1回実施・キャッシュし、`pointermove`以降はキャッシュ値を参照する
- [pattern] Generation カウンターで陳腐化コールバック無効化：複数の非同期操作が競合する場面で、カウンターを世代追跡に使い古い世代のコールバックを条件で無視することで競合状態を根絶
- [gotcha] Custom Element の接続/切断時リソース漏れ：`connectedCallback`で登録したタイマー・リスナーは`disconnectedCallback`で必ずクリアする。DOM再接続時は二重実行ガードを先頭に配置

## 2026-04-15 17:54 | teras-taya [ai]
- [gotcha] ドラッグUI終了時に「目標位置へジャンプ」→「アニメーション」する手順は視覚的ジャンプを招く。リリース位置のスナップショット保持 → そこからアニメーション開始すべき
- [pattern] `pointermove` など高頻度ハンドラーでの `getComputedStyle`/`offsetWidth` 計算はドラッグ開始時に1回キャッシュ。以降ループではキャッシュ値使用でレイアウトスラッシング防止
- [pattern] アニメーションコールバック（`done()` 等）の陳腐化は generation カウンター（シンプルなカウント変数）で防止。`clearTimeout` では enqueue 済みコールバック排除不可

## 2026-04-15 17:56 | teras-taya [ai]
- [pattern] `generation` カウンター使用で非同期コールバック（`transitionend` など）の陳腐化を防止。複数のアニメーション状態が競合する場合に有効
- [gotcha] `pointermove` イベントハンドラで毎回 `getComputedStyle`/`offsetWidth` を読むとレイアウトスラッシング。ドラッグ開始時にキャッシュして、ムーブハンドラはキャッシュ値のみ使用
- [pattern] `ResizeObserver` でレイアウト寸法を一度だけ計算・キャッシュし、座標計算関数を DOM 読み取りゼロの pure function に — フレーム内で複数回呼ばれる場合に効果的

## 2026-04-15 17:59 | teras-taya [ai]
- [pattern] Prestige カスタムエレメント内の非同期コールバック（`transitionend` など）は generation カウンター（インクリメント ID）で陳腐化を検出し、旧コールバックを無効化する
- [pattern] `pointermove` など頻発イベント内の `getComputedStyle()` / `offsetWidth` 読み取りは、イベント開始時に1回だけ計算してキャッシュし再利用する（レイアウトスラッシング防止）
- [gotcha] カスタムエレメントの `disconnectedCallback` で `clearTimeout()` / `removeEventListener()` 忘れはメモリリーク。`_bound` フラグガードと併用して二重登録も防ぐ

## 2026-04-15 18:03 | teras-taya [ai]
- [gotcha] `pointermove`ごとに`getComputedStyle`/`offsetWidth`呼ぶと毎フレーム強制レイアウト。ドラッグ開始時に1度だけ計算してキャッシュ推奨
- [pattern] generation カウンターで非同期イベント（`transitionend`など）の陳腐化防止：前世代コールバックをスキップさせる
- [gotcha] Web Components `connectedCallback`でイベントリスナー二重登録リスク。ガード + `disconnectedCallback`で`clearTimeout`忘れはメモリリーク

## 2026-04-15 18:08 | teras-taya [ai]
- [gotcha] Web Components のライフサイクル：`disconnectedCallback` でタイマー・イベントリスナーをクリアしないとメモリリーク・二重登録が発生。必ず cleanup を実装する
- [pattern] ドラッグ UI のパフォーマンス：レイアウト計算をドラッグ開始時にキャッシュして、高頻度の `pointermove` では計算結果のみ参照。スラッシング回避と同時に `_tx()` を pure な関数に
- [pattern] 非同期操作の競合制御：animation 完了コールバックなど非同期処理の状態を generation ID で追跡。前のアニメーション完了が新しい操作を上書きしないようガード

## 2026-04-15 18:25 | teras-taya [ai]
- [gotcha] Web Components で DOM 再接続時にイベントリスナーが二重登録される。connectedCallback 先頭でガード（_bound フラグ等）を置く。
- [pattern] ドラッグ中の重い DOM 計算（offsetWidth, getComputedStyle）をキャッシュして、_tx() は純粋計算化。ResizeObserver だけで寸法を更新。
- [gotcha] transitionend リスナーが新アニメーション時に無効化されないと、旧アニメーション完了時に誤発火。generation カウンターでリスナー ID を管理。

## 2026-04-15 18:40 | teras-taya [ai]
- [pattern] Web Components でイベントリスナー管理に AbortController を使用。disconnectedCallback で abort() して一括削除でき、メモリリーク・二重登録を防止
- [gotcha] pointermove など高頻度イベント内での DOM 読み取り（offsetWidth/getComputedStyle）はレイアウトスラッシング。開始時に1回だけ計算してキャッシュ、以後は値を再利用
- [gotcha] ドラッグ速度計算の除算で dt > 0 ガード漏れ → v = Infinity が発生して意図しない遷移。必ず条件式で保護してから除算

## 2026-04-15 18:43 | teras-taya [ai]
- [gotcha] DOM 再接続時にイベントリスナーが二重登録される — AbortController で listeners を一括管理し、disconnectedCallback で abort()・フラグリセットで確実に cleanup 必須
- [pattern] 非同期 complete callbacks（transitionend 等）では generation カウンターで古い世代をフィルタ。新操作開始時に increment し callback 内で generation 比較
- [gotcha] CSS transition の transitionend は「値が実際に変わる場合のみ」発火。同一スライドへの _slideTo() は no-op ガード（現在値 == 目標値なら return）で complete ハンドラーの誤発火を防止必須

## 2026-04-15 18:48 | teras-taya [ai]
- [pattern] `AbortController` でイベントリスナーを一括管理。`disconnectedCallback` で `abort()` + `_bound=false` 済みで reconnect 時の二重登録を防止。
- [gotcha] `transitionend` のバブリング対策は `e.target === this._track` チェック必須。子要素イベントが親処理に誤発火する。
- [gotcha] 同一スライド呼び出しで `transitionend` 発火しない → `force` パラメーターで強制実行。transition なしだと `_busy` ロック解放されず。

## 2026-04-15 18:51 | teras-taya [ai]
- [gotcha] `transitionend` はバブルイベント — 子要素の transition でも親リスナーが反応する。`e.target === this._track` チェックで発火元を限定必須
- [pattern] AbortController で全リスナーを signal で登録し、`disconnectedCallback` で `abort()` すれば、DOM 再接続時のリスナー二重登録が完全に回避できる
- [gotcha] スナップ復帰時に no-op ガード（`idx === _idx なら return`）を入れると `transitionend` が発火せず、`_busy` が永遠に `true` になる — 同一位置への遷移も明示的にアニメーション実行が必要な場合がある

## 2026-04-15 18:54 | teras-taya [ai]
- [gotcha] Animation state lock：no-op ガード（early return）で transitionend が発火せず _busy がロック。state 遷移が必要な場合は force フラグか条件付き処理が必須。
- [pattern] AbortController でリスナー一括管理：disconnect/reconnect 時の二重登録リスク。signal abort() で全リスナー削除が確実。
- [gotcha] CSS 意図しない混入：全体影響の CSS は git diff で毎回確認。マルチファイル編集時にキャッシュ残留で混入しやすい。

## 2026-04-15 18:58 | teras-taya [ai]
- [gotcha] Web Component で `disconnectedCallback` にタイマーやリスナーの cleanup を漏らしやすい→AbortController で一括管理すると安全
- [gotcha] `transitionend` はバブリングするため、複数のリスナーがあると旧アニメーションのリスナーが誤発火する→`e.target === this._track` で対象確認必須
- [pattern] DOM読み取り（`offsetWidth`など）は毎フレーム実行するのではなく、`ResizeObserver`等で必要な時点にキャッシュして pure な計算関数で再利用する

## 2026-04-15 19:01 | teras-taya

- [correction] - B) 上記の潜在的な問題を修正してから完成させる
- [correction] 同じ行番号で内容が違う。ファイルに複数の `when 'vendor'` ブロックがあるか確認します。

## 2026-04-15 19:01 | teras-taya [ai]
- [gotcha] Shopifyテーマ開発でPR引き継ぎ時は、現在のブランチと作業ディレクトリを確認すること。複数の機能ブランチがあると誤った場所で作業する可能性がある。
- [gotcha] ローカルファイルとリモートコミット内容が乖離することがある。行番号が同じでも内容が違う場合は`git diff HEAD`で確認が必須。
- [pattern] Liquidのメタオブジェクト参照処理は「型定義確認→参照値のnullチェック→`.title`が空時のフォールバック処理」の3段階で設計すること。


## 2026-04-15 19:03 | teras-taya [ai]
- [pattern] AbortController で イベントリスナー・タイマー・Observer を一括管理 → `disconnectedCallback` で `abort()` するだけで全登録が自動クリア。重複登録・メモリリークを確実に防ぐ
- [gotcha] `pointermove` など高頻度イベント内で `getComputedStyle` / `offsetWidth` を呼ぶとレイアウトスラッシング → 値をキャッシュ変数に保持し、イベント発生時は1回のみ更新、後続処理ではキャッシュ値を使用
- [gotcha] 同じスライド位置への `transitionend` が発火しない → `_busy` フラグが永遠にロック。`force` パラメーターや skip ガード条件を用意して意図しないリセット時に確実に次操作を許可すべし


## 2026-04-15 19:07 | teras-taya [ai]
- [gotcha] pointermove/touchmoveなどのイベントループ内でDOM読み取り（offsetWidth等）をするとレイアウトスラッシング。イベント開始時に一度だけ計算してキャッシュ値を使用する。
- [pattern] transitionendやdecode()など非同期イベントの誤発火を防ぐ。操作のたび世代カウンターを進めてリスナー内で世代チェック。古い世代のイベントは無視。
- [pattern] disconnectedCallback でAbortController.abort() + フラグresetで、DOM再接続時の二重登録とメモリリークを防止。


## 2026-04-15 19:11 | teras-taya [ai]
- [pattern] Web Components のドラッグ処理で計算値（translate など）をキャッシュし、`pointermove` では計算結果のみ使用。`getComputedStyle`/`offsetWidth` を毎回読まずレイアウトスラッシングを防ぐ
- [gotcha] スナップバック機能を実装する際、「同スライドには遷移しない」ガードが必要な場合がある。単純な `if (current === target) return` では UI 回復操作が不可能になる。強制実行パラメーターで解決
- [gotcha] Web Components の `disconnectedCallback` でタイマー・リスナー・Observer をクリア忘れすると要素が DOM から抜けてもメモリが解放されない。`AbortController` で一括管理し、かつ `_bound` フラグをリセット


## 2026-04-15 19:14 | teras-taya [ai]
- [gotcha] ドラッグ離し時にスナップ位置にジャンプしてからアニメーションすると視覚的ジャンプが発生 → リリース位置から直接スムーズにアニメーション開始する
- [pattern] `AbortController` で `connectedCallback/disconnectedCallback` のイベントリスナー登録/削除を一括管理すると DOM 再接続時の二重登録が防止できる
- [gotcha] `transitionend` が複数アニメーションをリッスンするとバブリングで古いリスナーが誤発火 → generation カウンターまたはターゲットチェック（`e.target === expectedElement`）で validation する



## 2026-04-15 21:40 | teras-taya [ai]
- [gotcha] Shopify テーマ開発で settings_data.json が diff に含まれることがある。コミット前に確認し、不要な場合は unstage すること。
- [pattern] リスト型メタフィールド（List of products）から複数商品を取得する際、Liquid ループで処理し、各商品のメタフィールド・価格・画像に順序付けアクセス。
- [pattern] サードパーティーペイドテーマ（Prestige など）への機能追加は既存セクション構造を尊重し、既存 Liquid ファイル内の特定ブロック末尾にレンダー呼び出しを注入するアプローチが効果的。


## 2026-04-15 21:45 | teras-taya [ai]
- [gotcha] Shopify theme の `settings_data.json` は自動同期でコミット差分に含まれやすく、マージ時に `main` と競合。メタフィールド設定追加時は特に注意し、必要に応じて `git checkout main -- config/settings_data.json` で除外。
- [gotcha] `shopify--discovery--product_recommendation.complementary_products` メタフィールドには当該商品自体が含まれる可能性がある。ループ内で商品 ID を比較してスキップ処理を実装しないと二重表示が発生。
- [pattern] Shopify メタフィールド実装時は、メタフィールド仕様（データ内容の重複・現在値の包含など）を実装前に確認。設計段階での仕様理解が後の修正コストを大幅削減。

## 2026-04-15 21:50 | teras-taya
- [pattern] 修正しました。


## 2026-04-15 21:50 | teras-taya [ai]
- [gotcha] Shopifyの `complementary_products` メタフィールドに当該商品自身が含まれる場合がある。ループ内で `product.id` との重複チェックでスキップ必須。
- [pattern] Shopify theme で `settings_data.json` は自動同期により変更される。PR作成時は事前に確認し、必要に応じてマージ時に `main` と同期させる手順を用意。
- [tip] メタフィールドデータをテンプレートで使う前に、バリデーション・フィルタリングステップを入れるとデータ品質の問題に強くなる。


## 2026-04-15 21:55 | teras-taya [ai]
- [gotcha] Shopifyメタフィールド（List of products）には対象商品自体が含まれていることがある — ループ内で`product.id`との一致判定を入れてスキップ必須
- [pattern] 複数カード要素の行揃えにはCSS subgridが有効 — 画像・テキスト・価格などの高さを自動統一できる
- [tip] 配列型メタフィールドの複数値を表示するなら`・`区切り結合で見栄え向上


## 2026-04-15 22:25 | teras-taya [ai]
- [gotcha] Shopifyテーマの `settings_data.json` は自動同期される。PR差分に含まれると競合リスクがあるため、マージ前に `main` と同期する処理が必要。
- [pattern] メタフィールドに自身のIDが含まれる構造では、ループ内で `id` 比較してスキップする処理を必ず追加。2重表示バグの原因になりやすい。
- [tip] 複数カード内の要素が可変行数（カテゴリーテキスト2行など）の場合、CSS subgrid で親グリッドの行を共有するとすべてのカードで要素の横位置が自動で揃う。


## 2026-04-15 22:30 | teras-taya [ai]
- [gotcha] Shopify で subgrid 使用時、カスタムフィールド未設定なら `<span>` が空になり行が消える。常時レンダリング＋`&nbsp;` で行確保。
- [pattern] メタフィールドに自身が含まれる場合、ループ内で ID 比較してスキップ。重複表示防止。
- [gotcha] Shopify section に新規ブロック追加時、schema 定義だけでなく template.json の `allow_blocks` リストにも追加しないと表示されない。

## 2026-04-15 22:55 | teras-taya [ai]
- [gotcha] Prestige テーマのセクション余白調整は `--section-vertical-spacing-override` カスタムプロパティを使う。他の名前では効果なし。
- [pattern] テーマの既存クラスをオーバーライドする際は、まずテーマが使用しているカスタムプロパティ名を確認してから `{%- style -%}` で上書きする。


## 2026-04-15 22:56 | teras-taya [ai]
- [gotcha] Prestigeテーマで section-spacing 上下余白を調整するには、セクション内 `{%- style -%}` で `--section-vertical-spacing-override: Xrem` のカスタムプロパティオーバーライドを設定する必要がある
- [pattern] 異なるブランチから特定コミットのみ現在ブランチに取り込む場合は `git cherry-pick <hash>` を使用。関連コミット複数の場合は取捨選別を慎重に行う
- [gotcha] リモートより遅れてるブランチにpushする前に必ず `git pull` で最新化してから push する

## 2026-04-15 22:57 | teras-taya
- [gotcha] 完了: - コミット: `style: NEWSセクションの上下余白を縮小（section-vertical-spacing-override: 3rem）`

## 2026-04-15 22:57 | teras-taya [ai]

- [gotcha] 注意: メタフィールドが未設定の商品では何も表示されません。`custom.category` も未設定の場合はカテゴリーテキストが省略されます。
- [pattern] Prestige のセクション余白は `--section-vertical-spacing-override` カスタムプロパティで制御。直接 margin/padding 指定ではなくこのプロパティを上書きする。
- [gotcha] 複数フィーチャーが混在するブランチから特定の修正のみ main に反映する場合は cherry-pick を使用。全マージすると無関係な機能が含まれるリスク。
- [tip] Prestige ではセクション内パディングとセクション間ギャップが異なるプロパティで制御される（`--section-vertical-spacing-override` vs `section-stack-gap`）。余白調整時は両方確認が必要。

## 2026-04-22 11:11 | mimc.co.jp-mailmagazine
- 作業: /Users/P130/Desktop/20260424.pdf
- 完了: `260424.html` を作成しました。
