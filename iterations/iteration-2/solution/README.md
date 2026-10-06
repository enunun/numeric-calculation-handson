# Iteration 2の模範解答：分散と性質ベーステスト

Iteration 2の演習を完成させたパッケージと，各手順の解説である．

- `Moments`(新規)：平均(補償付き総和)，Welfordの算法による標本分散，比較のための教科書の公式，分散の条件数．
- テストに`Random`を加え，乱数のデータを使う性質ベーステストとメタモルフィックテストを行う．

```julia
julia> data = [1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16];

julia> mean(data), variance(data), textbook_variance(data)
(1.00000001e9, 30.0, -170.66666666666666)
```

## 読み方

- [docs/iteration-2.md](docs/iteration-2.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0003を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-2/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散(Welford，教科書の公式)，分散の条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解，テストデータ，乱数のデータの生成，シード
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和，二次方程式，分散の結合テスト
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001〜0003
TESTLIST.md                          テストリスト
docs/iteration-2.md                  解説
```
