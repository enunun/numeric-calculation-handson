# Iteration 5の模範解答：指数関数とULP精度

Iteration 5の演習を完成させたパッケージと，各手順の解説である．
コースの最後のIterationで，`StableNumerics`はこれで完成する．

- `ElementaryFunctions`(新規)：Cody–Waiteの引数還元と13次のテイラー多項式による指数関数．誤差予算による上界は，正規化数の結果で1.3 ULP，非正規化数の結果で1.8 ULPである．
- `ErrorBounds`：ULP誤差を測る`ulp_error`を加えた．
- テストに，時間のかかる局所的な全数検査のグループ`exhaustive`を加えた．

```julia
julia> exponential(1.0), exponential(-Inf), exponential(710.0)
(2.7182818284590455, 0.0, Inf)
```

## 読み方

- [docs/iteration-5.md](docs/iteration-5.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0006を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-5/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．
局所的な全数検査だけを実行するには，`Pkg.test(test_args = ["exhaustive"])`とする．

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
test/runtests.jl                     テストの入口(unit/integration/exhaustiveのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，誤差予算の上界，シード
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和，二次方程式，分散，ピボット選択，最小二乗法の結合テスト
test/exhaustive/                     指数関数の局所的な全数検査
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001〜0006
TESTLIST.md                          テストリスト
docs/iteration-5.md                  解説
```
