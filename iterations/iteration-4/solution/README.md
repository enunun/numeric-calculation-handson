# Iteration 4の模範解答：最小二乗法と直交変換

Iteration 4の演習を完成させたパッケージと，各手順の解説である．

- `Triangular`(新規)：前進代入と後退代入．`LinearSolve`から取り出し，LU分解とQR分解で共有する．
- `LeastSquares`(新規)：ハウスホルダー変換によるQR分解，最小二乗問題の解法(QR分解，正規方程式)，多項式の当てはめ．
- テストに製造解(アダマール行列とパスカル行列で作る，答えのわかっている問題)を加えた．

```julia
julia> t = range(0, 1; length = 50); V = [ti^j for ti in t, j in 0:9]; y = V * ones(10);

julia> maximum(abs, lstsq_qr(V, y) .- 1), maximum(abs, lstsq_normal(V, y) .- 1)
(2.912069474447776e-10, 3.0555489688333104e-5)
```

## 読み方

- [docs/iteration-4.md](docs/iteration-4.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0005を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-4/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．
有理数の参照解を使うので，テストには30秒ほどかかる．

## ディレクトリの構成

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
src/LeastSquares.jl                  QR分解，最小二乗法(QR分解，正規方程式)，多項式の当てはめ
test/runtests.jl                     テストの入口(unit/integrationのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，シード
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和，二次方程式，分散，ピボット選択，最小二乗法の結合テスト
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001〜0005
TESTLIST.md                          テストリスト
docs/iteration-4.md                  解説
```
