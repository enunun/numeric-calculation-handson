# Iteration 0の演習：浮動小数点数と総和

このIterationでは，`StableNumerics`の最初の2つのモジュールを作る．

- `ErrorBounds`：単位丸めu，誤差解析の定数γₙ，有理数を参照解とする相対誤差．
- `Summation`：素朴な総和，無誤差変換`two_sum`，補償付き総和，総和の条件数．

浮動小数点数の丸め誤差を式で扱い，総和の誤差の上界を導き，それをテストの許容誤差にする．

```julia
julia> naive_sum([1e16, 1.0, -1e16]), compensated_sum([1e16, 1.0, -1e16])
(0.0, 1.0)
```

## 進め方

[docs/iteration-0.md](docs/iteration-0.md)の手順に従って進める．

1. 準備(0-1)：REPLとテストの実行を確かめる．
2. 文法と概念(0-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(0-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(0-4)：`design/`の3つの文書を書く．
5. テストファーストの実装(0-5)：テストリストの項目を1つずつ実装する．
6. 振り返り(0-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(0-7)：対ごとの総和を自分で加える．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   ErrorBoundsのスタブ
src/Summation.jl                     Summationのスタブ
test/runtests.jl                     テストの入口(テストファイルはまだ登録されていない)
design/modules.md                    モジュール依存図(これから書く)
design/error-spec.md                 誤差仕様書(これから書く)
design/adr/0001-compensated-summation.md  ADR(これから書く)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-0.md                  手順
```
