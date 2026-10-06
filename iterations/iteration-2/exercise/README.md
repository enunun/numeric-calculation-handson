# Iteration 2の演習：分散と性質ベーステスト

このIterationでは，データの平均と標本分散を求めるモジュール`Moments`を作る．
平均が標準偏差に比べて大きいデータでも，分散を正確に求める．

```julia
julia> data = [1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16];

julia> mean(data), variance(data), textbook_variance(data)
(1.00000001e9, 30.0, -170.66666666666666)
```

乱数でたくさんのデータを作り，結果が満たすべき性質(負にならない，平行移動で変わらない，など)を確かめる性質ベーステストを書く．

## 進め方

[docs/iteration-2.md](docs/iteration-2.md)の手順に従って進める．

1. 準備(2-1)：Iteration 1の模範解答から始まっていることを確かめる．
2. 文法と概念(2-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(2-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(2-4)：依存図，誤差仕様書を更新し，ADR 0003を書く．
5. テストファーストの実装(2-5)：テストリストの項目を1つずつ実装する．
6. 振り返り(2-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(2-7)：2つのデータの分散を合わせる関数を作る．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 1の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解とテストデータ
test/unit/                           単体テスト
test/integration/                    結合テスト
design/                              設計文書(Iteration 1の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-2.md                  手順
```
