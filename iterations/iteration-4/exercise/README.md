# Iteration 4の演習：最小二乗法と直交変換

このIterationでは，最小二乗問題をハウスホルダー変換によるQR分解で解くモジュール`LeastSquares`を作る．
その準備として，前進代入と後退代入を`LinearSolve`から新しいモジュール`Triangular`へ移す．

```julia
julia> t = range(0, 1; length = 50); V = [ti^j for ti in t, j in 0:9]; y = V * ones(10);

julia> maximum(abs, lstsq_qr(V, y) .- 1), maximum(abs, lstsq_normal(V, y) .- 1)
(2.912069474447776e-10, 3.0555489688333104e-5)
```

正規方程式が条件数を2乗する理由を学び，答えから問題を作る製造解でテストする．

## 進め方

[docs/iteration-4.md](docs/iteration-4.md)の手順に従って進める．

1. 準備(4-1)：Iteration 3の模範解答から始まっていることを確かめる．
2. 文法と概念(4-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(4-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(4-4)：依存図，誤差仕様書を更新し，ADR 0005を書く．
5. テストファーストの実装(4-5)：リファクタリングから始め，テストリストの項目を1つずつ実装する．
6. 振り返り(4-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(4-7)：重み付き最小二乗法を作る．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 3の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散，分散の条件数
src/LinearSolve.jl                   LU分解，連立1次方程式の解法，後退誤差，増大因子
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，シード
test/unit/                           単体テスト
test/integration/                    結合テスト
design/                              設計文書(Iteration 3の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-4.md                  手順
```
