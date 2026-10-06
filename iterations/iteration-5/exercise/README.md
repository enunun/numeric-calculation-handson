# Iteration 5の演習：指数関数とULP精度

このIterationでは，指数関数exp(x)を計算するモジュール`ElementaryFunctions`を作る．
引数還元と多項式近似の各段の誤差を足し合わせる誤差予算で，結果の誤差の上界をULPで示す．

```julia
julia> exponential(1.0), exponential(-Inf), exponential(710.0)
(2.7182818284590455, 0.0, Inf)

julia> ulp_error(exponential(0.5), exp(big(0.5)))
0.21309090040865203
```

標本検査，境界値検査，局所的な全数検査，既存の実装との差分テストを組み合わせて確かめる．

## 進め方

[docs/iteration-5.md](docs/iteration-5.md)の手順に従って進める．

1. 準備(5-1)：Iteration 4の模範解答から始まっていることを確かめる．
2. 文法と概念(5-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(5-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(5-4)：依存図，誤差仕様書(誤差予算)を更新し，ADR 0006を書く．
5. テストファーストの実装(5-5)：テストリストの項目を1つずつ実装する．時間のかかる検査は別のグループにする．
6. 振り返り(5-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(5-7)：`Float32`の指数関数を作り，区間のすべての入力を検査する．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 4の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散，分散の条件数
src/Triangular.jl                    前進代入，後退代入
src/LinearSolve.jl                   LU分解，連立1次方程式の解法，後退誤差，増大因子
src/LeastSquares.jl                  QR分解，最小二乗法，多項式の当てはめ
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，シード
test/unit/                           単体テスト
test/integration/                    結合テスト
design/                              設計文書(Iteration 4の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-5.md                  手順
```
