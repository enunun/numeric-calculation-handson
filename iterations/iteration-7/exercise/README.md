# Iteration 7の演習：刻み幅の自動調整とシンプレクティック法

このIterationでは，局所誤差の推定から刻み幅を自動で決める解法と，ハミルトン系の構造を保つStörmer–Verlet法を作る．
許容誤差が何を保証し何を保証しないかを見極め，保証されることだけをテストする．
長い時間の計算は，参照解の代わりに保存量で検査する．

```julia
julia> y, accepted, rejected = integrate_adaptive(f, 0.0, [1.0, 0.0], 2π; rtol = 1e-8, atol = 1e-8);

julia> maximum(abs, y - [1.0, 0.0]), accepted, rejected   # 大域誤差は許容誤差より大きい
(1.8317103522846878e-7, 712, 2)
```

## 進め方

[docs/iteration-7.md](docs/iteration-7.md)の手順に従って進める．

1. 準備(7-1)：Iteration 6の模範解答から始まっていることを確かめる．
2. 文法と概念(7-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(7-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(7-4)：依存図，誤差仕様書を更新し，ADR 0008を書く．
5. テストファーストの実装(7-5)：テストリストの項目を1つずつ実装する．
6. 振り返り(7-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(7-7)：FSALで右辺の評価を減らし，結果が変わらないことを確かめる．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 6の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/                                 Iteration 6までのモジュール(ODESolversまで)
test/runtests.jl                     テストの入口(unit/integration/exhaustiveのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，誤差予算の上界，観測次数の判定基準，シード
test/unit/                           単体テスト
test/integration/                    結合テスト
test/exhaustive/                     局所的な全数検査
design/                              設計文書(Iteration 6の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-7.md                  手順
```
