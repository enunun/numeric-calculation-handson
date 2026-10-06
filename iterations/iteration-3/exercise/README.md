# Iteration 3の演習：連立1次方程式と後退安定性

このIterationでは，LU分解で連立1次方程式を解くモジュール`LinearSolve`を作る．
解の精度を，厳密解を使わずに残差から計算できる後退誤差で確かめる．

```julia
julia> A = [1e-20 1.0; 1.0 1.0]; b = [1.0, 2.0];

julia> solve(lu_factorize(A; pivot = false), b), solve(lu_factorize(A), b)
([0.0, 1.0], [1.0, 1.0])
```

## 進め方

[docs/iteration-3.md](docs/iteration-3.md)の手順に従って進める．

1. 準備(3-1)：Iteration 2の模範解答から始まっていることを確かめる．
2. 文法と概念(3-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(3-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(3-4)：依存図，誤差仕様書を更新し，ADR 0004を書く．
5. テストファーストの実装(3-5)：`LinearAlgebra`を依存に加え，テストリストの項目を1つずつ実装する．
6. 振り返り(3-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(3-7)：反復改良で前進誤差を小さくする．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 2の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散，分散の条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解，テストデータ，乱数のデータの生成，シード
test/unit/                           単体テスト
test/integration/                    結合テスト
design/                              設計文書(Iteration 2の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-3.md                  手順
```
