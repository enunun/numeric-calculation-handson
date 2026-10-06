# Iteration 7の模範解答：刻み幅の自動調整とシンプレクティック法

Iteration 7の演習を完成させたパッケージと，各手順の解説である．
コースの最後のIterationで，`StableNumerics`はこれで完成する．

- `ODESolvers`：Bogacki–Shampineの埋め込みルンゲ＝クッタ法`bs32_step`と，刻み幅を自動で調整する`integrate_adaptive`を加えた．
- `Hamiltonian`(新規)：Störmer–Verlet法．調和振動子の修正エネルギーと中心力の角運動量を厳密に保つ．
- テストに，有理数で保存量を厳密に確かめる単体テスト，ケプラー問題の結合テスト，10⁶ステップの長時間の検査を加えた．

```julia
julia> y, accepted, rejected = integrate_adaptive(f, 0.0, [1.0, 0.0], 2π; rtol = 1e-8, atol = 1e-8);

julia> maximum(abs, y - [1.0, 0.0]), accepted, rejected   # 大域誤差は許容誤差より大きい
(1.8317103522846878e-7, 712, 2)
```

## 読み方

- [docs/iteration-7.md](docs/iteration-7.md)：演習の各手順の解説．
- [TESTLIST.md](TESTLIST.md)：テストリストの模範解答．
- [design/](design/modules.md)：設計文書の模範解答．ADR 0008を加えた．

テストは，リポジトリのルートで`mise run test:package iterations/iteration-7/solution`を実行するか，このディレクトリで`julia --project=.`を起動してPkgモードの`test`を実行する．
時間のかかる検査だけを実行するには，`Pkg.test(test_args = ["exhaustive"])`とする．

## ディレクトリの構成

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/StableNumerics.jl                モジュールをincludeし，関数を公開する
src/ErrorBounds.jl                   単位丸め，γₙ，相対誤差(有理数とBigFloat)，ULP誤差
src/ErrorFreeTransforms.jl           two_sum，two_prod
src/Summation.jl                     素朴な総和，補償付き総和，総和の条件数
src/Quadratic.jl                     判別式，実根，根の後退誤差と条件数
src/Moments.jl                       平均，標本分散，分散の条件数
src/Triangular.jl                    前進代入，後退代入
src/LinearSolve.jl                   LU分解，連立1次方程式の解法，後退誤差，増大因子
src/LeastSquares.jl                  QR分解，最小二乗法，多項式の当てはめ
src/ElementaryFunctions.jl           引数還元，指数関数
src/ODESolvers.jl                    Euler法，RK4，一定の刻み幅の積分，観測次数，リチャードソン外挿，Bogacki–Shampine法，刻み幅の自動調整
src/Hamiltonian.jl                   Störmer–Verlet法
test/runtests.jl                     テストの入口(unit/integration/exhaustiveのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，誤差予算の上界，観測次数の判定基準，保存量，シード
test/unit/                           モジュールごとの単体テスト
test/integration/                    総和，二次方程式，分散，ピボット選択，最小二乗法，振り子の収束，ケプラー問題の結合テスト
test/exhaustive/                     指数関数の局所的な全数検査，Störmer–Verlet法の長時間の検査
design/modules.md                    モジュール依存図
design/error-spec.md                 誤差仕様書
design/adr/                          ADR 0001〜0008
TESTLIST.md                          テストリスト
docs/iteration-7.md                  解説
