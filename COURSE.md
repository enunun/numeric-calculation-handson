# コース計画

このファイルは，教材を作る人(とエージェント)のためのコース計画である．
学習者向けの説明は[README.md](README.md)と[docs/ROADMAP.md](docs/ROADMAP.md)にある．

## 対象者と目標

- 対象者は，何らかの言語で関数とテストを書いた経験があり，数値解析は初めて学ぶ人である．大学初年級の微積分と線形代数は既知とする．Juliaの経験は問わない．
- 修了時の目標は次の3つである．
  - 丸め誤差・打ち切り誤差・条件数を理解し，テストの許容誤差(絶対・相対・ULP)を誤差界から根拠をもって決められる．
  - 厳密解のない計算を，性質・不変量・メタモルフィック関係によるテストで検査できる．
  - アルゴリズムの安定性を後退誤差で評価し，不安定な実装をテストで見つけられる．
- 言語はJulia 1.12である．教材は日本語で書く．
- 規模は6 Iteration(Iteration 0〜5)で，1 Iterationあたり90分程度とする．

## 題材

`StableNumerics`という，素朴に書くと壊れる数値計算を安定に計算するJuliaのライブラリを育てる．
総和 → 二次方程式 → 分散 → LU分解 → QR分解による最小二乗法 → 指数関数の順に機能を加え，Iterationごとに品質保証の手法を1つずつ増やす．
完成したライブラリの使用例と各Iterationの仕様は[docs/ROADMAP.md](docs/ROADMAP.md)にある．

## 設計文書

各パッケージの`design/`に，次の3種類の文書を置く．図はMermaidで書く．

| 文書 | ファイル | 示すこと | 育ち方 |
| --- | --- | --- | --- |
| モジュール依存図 | `design/modules.md` | `src/`のモジュールと，`using`/`import`による依存 | モジュールと依存の矢印が増える |
| 誤差仕様書 | `design/error-spec.md` | 公開する関数ごとの条件数・誤差界・テストの許容誤差と根拠・検証するテスト | 関数の行が増え，誤差の測り方(相対誤差 → 後退誤差 → ULP)が増える |
| ADR | `design/adr/NNNN-<題名>.md` | アルゴリズムを選んだ理由(状況・決定・結果・検証) | 1 Iterationにつき1つ増える |

- 依存図は`flowchart LR`の中に「`A --> B`」と「`A`」の行だけを書く．矢印は「AがBを使う」を表す．標準ライブラリ(`LinearAlgebra`など)は図に描かず，図の下の説明に書く．
- 誤差仕様書の表は，1列目に関数名をインラインコードで書き，最後の列に検証するテストファイルのパス(`test/...jl`)を書く．
- ADRの番号はIteration Nで`000(N+1)`とする．

## 開発環境

### Dev Container

- `.devcontainer/`のDockerfileは，mise公式イメージ(`jdxcode/mise`)に`mise.toml`のツールを入れる．
- ツールの版は`mise.toml`と`mise.lock`で固定する：Julia 1.12.7，Node.js 26.10.0，pnpm 12.6.0，lefthook 2.1.14，rtk 0.49.0．
- VS Codeの拡張機能は次のとおり．
  - Julia(`julialang.language-julia`)
  - Mermaidのプレビュー(`bierner.markdown-mermaid`)
  - markdownlint(`davidanson.vscode-markdownlint`)とtextlint(`3w36zj6.textlint`)
  - Claude Code
- Juliaのパッケージは標準ライブラリ(`Test`，`Random`，`LinearAlgebra`)だけを使う．外部のパッケージに依存しないので，オフラインでもテストできる．

### リポジトリの構成

```text
COURSE.md                       コース計画(教材を作る人向け)
README.md                       コースの概要とIterationの一覧(学習者向け)
.devcontainer/                  学習者が作業するDev Container
mise.toml, mise.lock            ツールの版とタスク
scripts/check_design.jl         設計文書の検査
scripts/test_all.jl             すべてのパッケージのテスト
docs/ROADMAP.md                 Iterationごとの要件・学ぶこと・設計文書の更新
docs/qa.md                      数値計算の品質保証の考え方
docs/tdd.md                     テスト駆動開発とテストリストの書き方
docs/design.md                  設計文書の書き方
docs/theory/iteration-N.md      Iteration Nで学ぶ数値計算の理論
docs/julia/iteration-N.md       Iteration Nで初めて使うJuliaの文法と機能
iterations/iteration-N/
  exercise/                     学習者が作業するパッケージ
  solution/                     完成したパッケージと模範解答
```

### パッケージ

- `exercise/`と`solution/`は，どちらも`StableNumerics`という名前の独立したJuliaのパッケージである．UUIDはすべてのIterationで同じ値を使う．
- パッケージの構成は次のとおり．

```text
Project.toml                    パッケージ名，UUID，依存，テスト専用の依存
src/StableNumerics.jl           各モジュールをincludeして公開する
src/<モジュール名>.jl            1ファイルに1モジュール(module ... end)
test/runtests.jl                テストの入口．引数でunit/integrationのグループを選べる
test/helpers.jl                 テストで使う参照解とテストデータ
test/unit/<モジュール名をsnake_caseにしたもの>_tests.jl
test/integration/<筋書きの名前>_tests.jl
design/                         設計文書
docs/iteration-N.md             演習：手順／模範解答：解説
README.md                       このIterationで作るもの，進め方，構成
TESTLIST.md                     テストリスト
```

- 単体テストは`using StableNumerics.<モジュール名>`でモジュールを読み込む．結合テストは`using StableNumerics`で公開されたAPIだけを使う．
- 各パッケージは独立しているので，「パッケージの登録」はパッケージのディレクトリを`--project`で有効にすることで行う．`Manifest.toml`はコミットしない．

### コマンド

| 目的 | コマンド |
| --- | --- |
| REPLを起動する | `julia --project=<パッケージ>`(または`mise run repl <パッケージ>`) |
| パッケージのテスト | REPLのPkgモードで`test`，または`mise run test:package <パッケージ>` |
| 単体テストだけ | `Pkg.test(test_args = ["unit"])` |
| すべてのテスト | `mise run test` |
| 設計文書の検査 | `mise run design [パッケージ...]` |
| すべての検査(CIと同じ) | `mise run check` |

### 教材の検査

- `mise run check`は，Markdownのリント(textlint，markdownlint)，設計文書の検査，すべてのパッケージのテストを実行する．
- 設計文書の検査(`scripts/check_design.jl`)は次を確かめる．
  - リポジトリのすべてのMermaidの図が，このコースで使うflowchartの書き方に従っている(図の構文の検査)．
  - 依存図の矢印とモジュールが，`src/*.jl`の`module`と`using`/`import`に一致する．
  - 誤差仕様書の表の関数が，`StableNumerics`がexportする関数(小文字で始まる名前)に一致し，検証するテストのファイルが存在する．
- Iteration 0の演習は設計文書がまだ書かれていないので，引数なしの`mise run design`の対象から外す．学習者はパッケージを引数に指定して検査する．

### 学習者が行うツール操作

| 操作 | 最初に完全な形で示すIteration |
| --- | --- |
| `julia --project=.`でREPLを起動し，`using StableNumerics`する | 0 |
| Pkgモード(`]`)で`test`を実行する | 0 |
| `test/runtests.jl`にテストファイルを`include`で登録する | 0 |
| `mise run design <パッケージ>`で設計文書を検査する | 0 |
| `Pkg.test(test_args = ["unit"])`で単体テストだけを実行する | 1 |
| `Project.toml`の`[extras]`と`[targets]`にテスト専用の依存を加える | 2 |
| Pkgモードの`add`でパッケージの依存を加える | 3 |
| REPLで特定のテストファイルだけを`include`して実行する | 4 |
| 時間のかかるテストを別のグループに分けて実行する | 5 |

### ノート

- 数値計算の理論のノートは`docs/theory/iteration-N.md`に，Juliaの文法と機能のノートは`docs/julia/iteration-N.md`に置く．
- それぞれの目次は`docs/theory/README.md`と`docs/julia/README.md`に置く．

## Iteration 0の演習の形

- `src/`には，`StableNumerics.jl`(2つのモジュールの`include`と`export`)と，`ErrorBounds.jl`・`Summation.jl`のスタブを置く．スタブの関数は正しいシグネチャと短いdocstringを持ち，呼ぶと`error("…は未実装")`で失敗する．
- `test/runtests.jl`は，テストのグループ(unit/integration)を選ぶ入口だけを持ち，テストファイルを1つも`include`していない．`test/helpers.jl`，`test/unit/`，`test/integration/`は学習者が作る．
- `design/`の3つの文書(`modules.md`，`error-spec.md`，`adr/0001-compensated-summation.md`)は，見出しと，何を書くかを説明するHTMLコメントだけを持つ．
- `TESTLIST.md`は，単体テストと結合テストの見出しだけを持つ．

## 落とし穴

- Juliaの文字列の補間`$name`の直後に全角文字(`：`，`が`など)を続けると，全角文字まで変数名とみなされる．日本語の文に埋め込むときは`$(name)`と書く．
- `Pkg.test`は`--warn-overwrite=yes`でテストを実行する．複数のテストファイルで同じ関数を定義すると警告が出るので，共通の補助関数は`test/helpers.jl`にまとめる．
- `@test`の中で例外が起きると，その`@testset`の残りの`@test`は実行されない．スタブ(未実装)の段階でRedを確かめるときは，Error(例外)とFail(期待値の不一致)を区別して読む．
- `mise lock`が書く`mise.lock`の形式は，miseの版で変わる．Dockerfileのベースイメージ(`jdxcode/mise`)の版は，`mise lock`を実行したmiseの版以上にそろえる．古い版のmiseは新しい形式を読めず，`mise install --locked`が失敗する．
- MarkdownのHTMLコメント(`<!-- ... -->`)の中に，Mermaidの矢印`-->`を書かない．コメントがそこで閉じ，残りが本文として表示される．
- `isapprox`(`≈`)の既定の許容誤差は`rtol = √eps`で，0との比較では`atol`を指定しない限り必ず偽になる．教材では，許容誤差を必ず誤差界から明示する．
