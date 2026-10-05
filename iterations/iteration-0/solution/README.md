# Iteration 0の模範解答：浮動小数点数と総和

Iteration 0の演習を完成させたパッケージと，各手順の解説である．

- `ErrorBounds`：単位丸めu，誤差解析の定数γₙ，有理数を参照解とする相対誤差．
- `Summation`：素朴な総和，無誤差変換`two_sum`，補償付き総和(Sum2)，総和の条件数．

```julia
julia> naive_sum([1e16, 1.0, -1e16]), compensated_sum([1e16, 1.0, -1e16])
(0.0, 1.0)
```

## 読み方

- [docs/iteration-0.md](docs/iteration-0.md)：演習の各手順の解説．テストリストの選び方，設計文書の考え方，実装の進め方，振り返りの答え．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-0/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差
src/Summation.jl                     two_sum，素朴な総和，補償付き総和，総和の条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      有理数による参照解と，誤差界の検査に使うデータ
test/unit/error_bounds_tests.jl      ErrorBoundsの単体テスト
test/unit/summation_tests.jl         Summationの単体テスト
test/integration/summation_accuracy_tests.jl  条件数から誤差を見積もる結合テスト
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/0001-compensated-summation.md  ADR：補償付き総和にSum2を使う
TESTLIST.md                          テストリスト
docs/iteration-0.md                  解説
```
