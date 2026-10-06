# Iteration 6の模範解答：常微分方程式と収束次数

Iteration 6の演習を完成させたパッケージと，各手順の解説である．

- `ODESolvers`(新規)：Euler法，古典的な4次のルンゲ＝クッタ法(RK4)，一定の刻み幅で解く`integrate`，観測次数，リチャードソン外挿による誤差の推定．
- テストに，製造解の問題で観測次数を確かめる単体テストと，厳密解のわからない振り子で収束次数を確かめる結合テストを加えた．

```julia
julia> observed_order(e(100, euler_step), e(200, euler_step)), observed_order(e(100, rk4_step), e(200, rk4_step))
(1.0703230456058292, 3.9984734943214324)
```

## 読み方

- [docs/iteration-6.md](docs/iteration-6.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0007を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-6/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)，ULP誤差
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散，分散の条件数
src/Triangular.jl                    前進代入，後退代入
src/LinearSolve.jl                   LU分解，連立1次方程式の解法，後退誤差，増大因子
src/LeastSquares.jl                  QR分解，最小二乗法，多項式の当てはめ
src/ElementaryFunctions.jl           引数還元，指数関数
src/ODESolvers.jl                    Euler法，RK4，一定の刻み幅の積分，観測次数，リチャードソン外挿
test/runtests.jl                     テストの入口(unit/integration/exhaustiveのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，誤差予算の上界，観測次数の判定基準，シード
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和，二次方程式，分散，ピボット選択，最小二乗法，振り子の収束の結合テスト
test/exhaustive/                     指数関数の局所的な全数検査
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001〜0007
TESTLIST.md                          テストリスト
docs/iteration-6.md                  解説
