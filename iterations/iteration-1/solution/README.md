# Iteration 1の模範解答：二次方程式と後退誤差

Iteration 1の演習を完成させたパッケージと，各手順の解説である．

- `ErrorFreeTransforms`(新規)：和と積の無誤差変換`two_sum`，`two_prod`．
- `Quadratic`(新規)：判別式，二次方程式の実根，根の後退誤差と条件数．
- `ErrorBounds`：`BigFloat`の参照解に対する相対誤差を加えた．
- `Summation`：`two_sum`を`ErrorFreeTransforms`から使う．

```julia
julia> quadratic_roots(94906265.625, -189812534.0, 94906268.375)
(1.0, 1.0000000289759583)
```

## 読み方

- [docs/iteration-1.md](docs/iteration-1.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0002を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-1/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，テスト専用の依存(Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解(有理数，BigFloat)とテストデータ
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和の精度の見積もり，二次方程式の根の品質
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001(補償付き総和)，0002(二次方程式)
TESTLIST.md                          テストリスト
docs/iteration-1.md                  解説
```
