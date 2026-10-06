# Iteration 1の演習：二次方程式と後退誤差

このIterationでは，二次方程式の実根を求めるモジュール`Quadratic`を作る．
あわせて，`two_sum`を新しいモジュール`ErrorFreeTransforms`へ移し，fmaによる積の無誤差変換`two_prod`を加える．

```julia
julia> quadratic_roots(1.0, 1e8, 1.0)
(-1.0e8, -1.0e-8)

julia> quadratic_roots(94906265.625, -189812534.0, 94906268.375)
(1.0, 1.0000000289759583)
```

計算結果の誤差は，問題の条件数とアルゴリズムの後退誤差に分けて考える．検査には，高精度の参照解(`BigFloat`)と性質(解と係数の関係)を使う．

## 進め方

[docs/iteration-1.md](docs/iteration-1.md)の手順に従って進める．

1. 準備(1-1)：Iteration 0の模範解答から始まっていることを確かめる．
2. 文法と概念(1-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(1-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(1-4)：依存図，誤差仕様書を更新し，ADR 0002を書く．
5. テストファーストの実装(1-5)：リファクタリングから始め，テストリストの項目を1つずつ実装する．
6. 振り返り(1-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(1-7)：係数が大きくてもオーバーフローしないようにする．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 0の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差
src/Summation.jl                     two_sum，素朴な総和，補償付き総和，総和の条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解とテストデータ
test/unit/                           単体テスト
test/integration/                    結合テスト
design/                              設計文書(Iteration 0の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-1.md                  手順
```
