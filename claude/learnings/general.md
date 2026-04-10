# General Learnings
<!-- domain: general — ツール・git・CLI・横断的な学び -->

## メール / HTML

- [tip] メルマガHTMLで `!important` は Outlook 回避用として有効
- [gotcha] PDFや画像内のテキストが読み取れない場合、推測で文章を作らず必ずユーザーに確認する。特にメール本文・商品説明文など正確さが重要なコンテンツは勝手に創作しない。

## JavaScript / フロントエンド

- [pattern] fetch成功判定は `res.ok` を必ず確認する。成功時だけ状態を記録し、失敗時は再試行できるようにする。
- [pattern] 非同期初期化待ち: `.dd-button.click()` のようなDOM依存呼び出しではなく `window.discountDeckInstance.showCoupons()` を直接呼び出す — ポーリングで初期化を待つ実装に合わせるため。
- [open] Rivyoが `DOMContentLoaded` より後にバッジを注入する場合は `MutationObserver` への変更が必要になる可能性がある（実装後に確認）。

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

## Recurring Patterns (updated 2026-04-09)
- [shopify] インポートデータの列名・フォーマット厳格性: Matrixify列名差異・Line:Type必須・タグ上書き — seen 6 times
- [shopify] Liquidフィルター精度: divided_by整数除算・img_url廃止・リスト型メタフィールド出力 — seen 5 times
- [matrixify] MatrixifyはShopify純正CSVと列名形式が異なる（型サフィックス付き・Fulfillment Line必須） — seen 3 times
- [js] 非同期初期化待ちポーリング実装: windowフラグによるシングルトン化・名前空間付きイベント登録・DOM依存呼び出し回避 — seen 3 times

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

## 2026-04-10 12:18 | Pinup-Closet_ver01 [ai]
- [gotcha] 管理画面ページコンテンツのHTMLから参照する要素（data-remodal-target等）は、テーマ側で無条件レンダリングされているか確認必須。Liquid条件分岐で出力制限されていると該当ページに存在しない
- [pattern] product contextやページタイプに依存するモーダルは、複数ページから参照される可能性がある場合、条件を緩和するか汎用版を用意する
- [tip] Remodal実装時は、data-remodal-id と data-remodal-target の対応をテンプレートとJS両面から検証する

## 2026-04-10 12:21 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで条件付き出力されるコンポーネント（モーダル、スニペット等）は、参照元が複数ページタイプにまたがる場合、すべてのコンテキストで出力されるか条件を見直す必要がある
- [pattern] モーダル不表示の調査は、ボタンの`data-remodal-target`値から逆引きして対応する`data-remodal-id`のHTML定義を探すことから始める
- [correction] 新しいモーダルを追加する前に、対象商品が既存のモーダルをどう参照しているか確認し、一貫性を保つべき

## 2026-04-10 12:23 | Pinup-Closet_ver01
- 作業: 以下ページのマイサイズを見つけるの挙動が変です。本当はチャート式になっているはずなので確認してください。
- 完了: 追加しました。ただし、これはJSのオーバーライドです。**`modal-sylphide` のHTMLモーダル本体がpage.content（Shopify管理画面のページ本文）に存在しているか**が前提になります。

## 2026-04-10 12:23 | Pinup-Closet_ver01

## 2026-04-10 12:23 | Pinup-Closet_ver01
- [correction] 具体的には条件を変更します。修正してよいですか？

## 2026-04-10 12:23 | Pinup-Closet_ver01 [ai]
- [gotcha] LPページはproduct contextを持たないため、`if product.id == ...` で条件分岐されたモーダルHTMLは出力されない。汎用モーダルはページ本文またはテンプレート上部に無条件で配置する必要がある
- [pattern] Shopify管理画面のページコンテンツに定義されたモーダル（`data-remodal-id`）に対して、テーマのJS側でクリックハンドラをオーバーライドすることで機能追加できる（Sireneの例参照）
- [tip] モーダルが動作しない場合、`data-remodal-target` 値がHTMLに存在するか確認する際、ページコンテンツ（Shopify管理画面）とテンプレート両方をチェックが必須

## 2026-04-10 12:23 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで `data-remodal-target` を使う場合、モーダルのHTML本体が `page.content`（管理画面ページ本文）内に定義されているか、テーマファイル内に定義されているか必ず確認する。テーマファイルだけでは完全な構造は見えない。
- [pattern] Shopifyテーマで同一コンポーネント（モーダル等）が複数LPで使われる場合、JSオーバーライドで動作をページごとにカスタマイズするアプローチ（Sireneの事例）が保守性が高い。Liquid条件分岐より柔軟。
- [tip] Shopifyテーマのモーダル実装確認はブラウザDevToolsで `data-remodal-id` 属性の有無を検査するのが最短。テーマファイルと管理画面を行き来するより効率的。

## 2026-04-10 12:26 | Pinup-Closet_ver01

## 2026-04-10 12:26 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopify LP ページではproduct contextがないため、layout/theme.liquid の商品ID条件分岐（`if product.id == ...`）内で定義されたモーダルは表示されない。LP用モーダルは条件を変更するか別途定義が必要。
- [pattern] Shopify LPページでモーダル機能を実装する場合、Sireneパターン（page.contentにHTMLを直書き + ページテンプレートでJSオーバーライド）を踏襲。modal-sireneのように `data-remodal-id` でページ本文に定義し、ページテンプレート側でイベントハンドラを追加。
- [tip] モーダル問題が複数ある場合、ブラウザデベロッパーツールで実際にレンダリングされているHTMLを確認し、page.content内のモーダル定義状況を把握してから修正。テーマファイルだけでは管理画面コンテンツ確認不可。

## 2026-04-10 12:50 | Pinup-Closet_ver01
- 重要な発見です。興味深い矛盾点があります：
- 重要な発見です。チャンクサイズが5000文字では複数モーダルをまたいで読んでしまっています。モーダルの出現順序を確認します。
- [gotcha] 重要なバグを発見しました：

## 2026-04-10 12:50 | Pinup-Closet_ver01 [ai]
- [gotcha] page.content（Shopify管理画面で編集するページ本文）に埋め込まれたHTMLはテーマテンプレート分析では見えない。モーダルIDとボタンターゲットのペアリング検証にはブラウザ検査が必須。
- [gotcha] 条件付きレンダリング（`if product.id == ...`）でモーダルを出力すると、そのコンテキストにない場所（LP等）ではHTML本体が存在しない。ボタンのみ存在する矛盾状態になる。
- [pattern] LP固有UI実装パターン：モーダルHTMLはpage.contentに定義、JSハンドラはpage.lp-corset*.liquidで層分離する。ブランド追加時、LiquidはLP条件のみ、JSハンドラを足すだけで拡張可能。

## 2026-04-10 12:53 | Pinup-Closet_ver01
- 完了: PRが必要な場合は、mainを1コミット戻してブランチから再PRする形になりますが、**既にmainにマージ済み**の状態なので、このままShopifyにpushする方が早いです。どうしますか？

## 2026-04-10 12:53 | Pinup-Closet_ver01
- - [gotcha] 商品ページ向けに`if product.id == ...`条件でモーダルHTMLをレンダリングすると、product contextを持たないLPページでは出力されない。複数ページタイプで使うモーダルは条件設計に注意。

## 2026-04-10 12:53 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマでpage.contentに埋め込まれたHTMLモーダルはテーマファイルには見えない。ブラウザのデベロッパーツールで実際に`data-remodal-id`が存在するか確認が必須。
- [gotcha] 商品ページ向けに`if product.id == ...`条件でモーダルHTMLをレンダリングすると、product contextを持たないLPページでは出力されない。複数ページタイプで使うモーダルは条件設計に注意。
- [pattern] Shopifyテーマで複数ブランド向けモーダルを実装する場合、LiquidファイルのJSオーバーライド箇所で各ブランドID毎のハンドラを定義し、page.content側で共通のdata-remodal-idを指定する構造が統一的。

## 2026-04-10 12:55 | Pinup-Closet_ver01
- [correction] 修正してください。

## 2026-04-10 12:55 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで page.content 内のボタンと theme.liquid のモーダル定義が分離していると、page.content からは見えない product context 条件分岐でモーダルが非表示になることがある。LPページでは product context がないため注意。
- [pattern] モーダル実装は「HTML定義（Liquid）＋イベントハンドラ（JS）＋ボタンの data-remodal-target」の3点セット確認が必須。1つ欠けると動作しない。
- [tip] page.content に書かれた data-remodal-target の値とテーマ側の data-remodal-id が一致しているか、ブラウザのデベロッパーツールで実HTML をレンダリング確認するのが確実。

## 2026-04-10 12:56 | Pinup-Closet_ver01

## 2026-04-10 12:57 | Pinup-Closet_ver01
- - [gotcha] ページコンテンツで指定した`data-remodal-target`などのIDに対応するHTMLやJSハンドラがテーマ側に存在しないと動作しない。ページ側とテーマ側の整合性確認が重要。

## 2026-04-10 12:56 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマの`page.content`内のHTML要素はLiquidテンプレートから見えない。ページコンテンツ関連のデバッグ時はブラウザまたは管理画面での直接確認が必須。
- [gotcha] ページコンテンツで指定した`data-remodal-target`などのIDに対応するHTMLやJSハンドラがテーマ側に存在しないと動作しない。ページ側とテーマ側の整合性確認が重要。
- [pattern] LPページなど複数の場面で再利用するモーダル・コンポーネントは、`if product.id == ...`の個別条件で制限せず、より広いスコープで定義する。

## 2026-04-10 12:57 | Pinup-Closet_ver01

## 2026-04-10 12:57 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopify theme で page.content（管理画面コンテンツ）に埋め込まれた HTML と Liquid テンプレート内のモーダル定義は、テーマファイルだけでは対応関係を検証できない。button の data-remodal-target が実装前に page.content の構造を確認必須。
- [pattern] LP やページ固有のモーダル JS オーバーライド（イベントハンドラ追加）は、そのページテンプレート（page.lp-corset01.liquid など）に直接記述するとロジック と使用箇所が一緒に管理でき保守性が上がる。
- [tip] 複数の商品/モーダル種類がある場合、各モーダルの使用条件（product context 有無、ページタイプ等）と data-remodal-target の対応を一度整理してから修正すると、ボタン-モーダル不一致を防ぎやすい。

## 2026-04-10 12:59 | Pinup-Closet_ver01

## 2026-04-10 12:59 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで商品ページ専用モーダル（`if product.id == ...`条件）をLP/ページから呼び出す場合、HTMLレンダリング条件を確認が必須。ボタンのターゲット指定だけでは不足。
- [pattern] 複数ブランドのLP診断モーダル（Sirene/Sylphide）は`page.content`HTML定義 + テンプレート側のブランド別JSオーバーライドパターンで管理する（PR #26から）。
- [gotcha] モーダル動作失敗は複合原因（HTML未出力 + JSハンドラ未定義）の場合がある。両方をセットで確認する。

## 2026-04-10 13:00 | Pinup-Closet_ver01

## 2026-04-10 13:00 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopify page.contentに埋め込まれたHTMLはテーマLiquidから見えない。モーダルやボタンの挙動を調査する際は、管理画面コンテンツとテーマファイル両方を確認必須
- [pattern] テンプレート内のモーダルをproduct ID条件で制限すると、商品ページ以外（LP）で参照されて破綻する。複数ページで共用する場合は `request.page_type` ベースの条件分岐が拡張性が高い
- [tip] カスタムモーダル実装時は、JSハンドラ（クリックイベント）とHTMLの存在を同時に確認。一方だけでは動作しない

## 2026-04-10 13:30 | P130
- [open] - 楽天スーパーロジスティクス・オープンロジ（中小向けB2C、酒類可否要確認）

## 2026-04-10 13:30 | P130 [ai]
- [gotcha] 「EC機能が必要」と予想してECカート選定を進めると、決済・カート・商品管理の過剰機能で開発期間超過。キャンペーン申込＋コード照合のみならFormrunやカスタムLPで十分
- [pattern] 酒類配送が必要な場合、ECカートではなく「酒類倉庫業許可を持つ3PL業者」を先に決定してLPと分離。キャンペーン専業会社なら一括受託可能
- [tip] ユニークコード10,000個の管理は、事前CSV生成 → DB格納 → 申込時照合・使用済みフラグ更新で実装。ランダム生成ロジックより運用が単純

## 2026-04-10 13:30 | P130
- [gotcha] 2. 酒類の年齢確認 → 法的要件（酒税法・未成年飲酒禁止法）の確認が必要

## 2026-04-10 13:30 | P130 [ai]
- [gotcha] 見た目はEC案件でも、決済機能が不要なら過剰装備化する。要件の本質を見極めることが重要
- [pattern] 複合案件（LP＋コード管理＋物流）はスコープを分割し、デジタル部分と物流部分の対応範囲を早期に明確化する
- [tip] 酒類キャンペーンは年齢確認法務・3PL酒類対応可否・役割分担を受注前に全て確認する必要がある

## 2026-04-10 13:56 | Pinup-Closet_ver01

## 2026-04-10 13:56 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyページ（page.content）のHTML内容はテンプレートから見えない。ボタン実装とモーダル不一致の原因特定には、ブラウザのデベロッパーツール確認が必須。
- [gotcha] LP ページは product context がないため、商品ページの `if product.id == ...` 条件でレンダリングされるモーダルは LP では出力されない。LP 用と product 用の条件分岐を分離して管理する必要がある。
- [pattern] 複数 LP ページで複数モーダルを使う場合、page.content に各モーダル HTML を定義し、テンプレート側（page-xxx.liquid）で JS オーバーライドする二層構造が有効。

## 2026-04-10 13:58 | Pinup-Closet_ver01
- 完了: `550adc4` をプッシュしました。[layout/theme.liquid:817](layout/theme.liquid#L817) の開くボタンクリック時に `.js-size-number.val('')` を追加しました。

## 2026-04-10 13:58 | Pinup-Closet_ver01 [ai]
- [gotcha] page.contentの管理画面HTMLと.liquidテンプレート内のHTMLは別物。デベロッパーツールでpage.contentのHTMLを確認しないと、テーマファイルだけでは検証不完全。
- [pattern] product contextが必須なUIは条件分岐で出力制限されることが多い。LPページなど異なるコンテキストで使う場合は、テンプレートの条件を拡張してHTMLが出力されることを確認する。
- [gotcha] モーダルやボタン実装では、HTMLの`data-remodal-id`定義とJSのイベントハンドラ両方が揃っていないと動作しない。片方だけでは不完全。

## 2026-04-10 13:59 | Pinup-Closet_ver01

## 2026-04-10 14:00 | Pinup-Closet_ver01
- - [gotcha] Shopifyテーマで複数ページでモーダルを共有する際、page.content（管理画面）のHTMLと`layout/theme.liquid`のHTMLの乖離を必ず確認する。product contextがないページではモーダルHTMLが出力されない可能性がある。

## 2026-04-10 13:59 | Pinup-Closet_ver01 [ai]
- [gotcha] Shopifyテーマで複数ページでモーダルを共有する際、page.content（管理画面）のHTMLと`layout/theme.liquid`のHTMLの乖離を必ず確認する。product contextがないページではモーダルHTMLが出力されない可能性がある。
- [pattern] テーマの既存実装パターン（例：Sirene用のJS実装）を参考に、同様の構造を別機能（Sylphide）に適用する方式が有効。一度動いているパターンを流用するほうが安全。
- [gotcha] 商品ページの条件分岐内（`if product.id == ...`）でレンダリングされるコンポーネントは、該当ページのproduct contextがないLPページでは描画されない。複数ページで共有するモーダルの条件分岐を見直す際に注意。

## 2026-04-10 14:06 | pietro-onlineshop_ver01
- [correction] ShopifyのリダイレクトはこのURL形式だとだめ？
- [correction] &以降がだめ？

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

## 2026-04-10 14:23 | dotfiles
- [correction] 自走できるなら複合コマンド許可したはずなのですが。設定見直してください。
- [gotcha] **WRONG** (replaces existing permissions):

## 2026-04-10 14:23 | dotfiles [ai]
- [gotcha] Claude Code permission rule で `Bash(*)` は真のワイルドカードではなく「`*` で始まるコマンド」と解釈される。複合コマンド許可は `"Bash"` のみが catch-all
- [gotcha] `defaultMode: "bypassPermissions"` でも `deny` リストは有効。複合コマンドに deny ルールマッチが含まれると弾かれる

## 2026-04-10 14:25 | dotfiles
- 作業: 自走できるなら複合コマンド許可したはずなのですが。設定見直してください。
- 完了: `"Bash(*)"` → `"Bash"` に修正しました。これが真のキャッチオールで、`&&`、`||`、`|`、`;` を含む複合コマンドもすべてカバーします。`defaultMode: "bypassPermissions"` は維持されているので二重の保険になっています。

## 2026-04-10 14:25 | dotfiles [ai]
- [gotcha] Claude Code の permission rule で `Bash(*)` はワイルドカード扱いではなく「`*` で始まるコマンド」と解釈される。複合コマンドの catch-all は `"Bash"` のみが正解。
- [pattern] 複合コマンド（`&&`, `||`, `|`, `;`）を自動許可するには `defaultMode: "bypassPermissions"` + `"Bash"` catch-all で実現。
- [tip] `defaultMode: "bypassPermissions"` でも deny ルール内のパターンマッチ（例：`Bash(rm -rf *)`）は有効なため、複合コマンドが deny に該当するコマンド含むと弾かれる可能性。

## 2026-04-10 14:26 | dotfiles
- ただし 注意点が1つあります: `"Bash(rm -rf *)"` のルールは `rm -rf ./node_modules` のような正当な操作も弾く可能性があります。必要なら `rm -rf ./` 系のみ許可するよう調整できます。

## 2026-04-10 14:26 | dotfiles [ai]
- [gotcha] `Bash(*)` は真のキャッチオールではなく「`*` で始まるコマンド」と解釈される。複合コマンド許可には `"Bash"` のみが正しい。
- [gotcha] `defaultMode: "bypassPermissions"` でも `deny` リストは有効に機能する。フック層の実装と deny ルール間で重複保護が発生する場合がある。
- [pattern] フック（PreToolUse など）で既に実装されている制御は、deny ルールで二重に指定しない。単一層での管理が設定の可読性を保つ。

## 2026-04-10 16:29 | pietro-onlineshop_ver01 [ai]
- [gotcha] Shopifyメタフィールドをインポートする際、型（boolean/text等）を事前確認しないと型不一致エラーになる
- [pattern] メタフィールドインポート前に「型定義→値形式→対象レコード」を確認してからスクリプトを作成する
- [tip] インポート対象が「新規追加か既存更新か」「どの顧客範囲か」を明確にしないとマッピングが曖昧になる

## 2026-04-10 16:38 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopifyメタフィールドをインポートする前に、そのメタフィールドが定義済みであることを確認。Matrixifyで`Metafield: custom.xxx [type]`を指定する際、型名（`single_line_text_field`など）は定義時の型と一致していることが必須
- [gotcha] 要件が不明な場合、推測で複数の質問を重ねるより先に、サンプルファイルを実際に読み込んで現物から仕様を把握する。往復回数を減らせる
- [tip] Matrixifyのメタフィールド値は型に応じた形式で指定（`single_line_text_field`なら`"希望する"`のような文字列）。テストインポートで値の形式が正しいことを早期に確認

## 2026-04-10 16:39 | pietro-onlineshop_ver01
- [pattern] 完了しました。

## 2026-04-10 16:39 | pietro-onlineshop_ver01 [ai]
- [pattern] Shopify Matrixifyのメタフィールドインポートでは、顧客IDがなくてもEmailで顧客を特定できる。ID追加は後から必要に応じて対応
- [tip] 顧客メタフィールドのMatrixifyフォーマット: 「ID, Email, Command, Metafield: custom.XXX [型]」で値を指定

## 2026-04-10 16:40 | pietro-onlineshop_ver01
- 作業: matrixifyのインポートファイル作成をお願いします
- 完了: サンプルファイルにはIDがありましたが、ソースデータにはIDがないためEmail照合で作成しました。MatrixifyはEmailでも顧客を特定できます。インポート時に問題があればIDを追加する方法に切り替えます。
