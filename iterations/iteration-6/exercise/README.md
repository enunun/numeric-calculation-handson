# Iteration 6の演習：常微分方程式と収束次数

このIterationでは，常微分方程式の初期値問題を解くモジュール`ODESolvers`を作る．
Euler法と古典的な4次のルンゲ＝クッタ法(RK4)を実装し，誤差の大きさではなく「刻み幅を小さくしたときの誤差の減り方(収束次数)」で正しさを確かめる．

```julia
julia> observed_order(e(100, euler_step), e(200, euler_step)), observed_order(e(100, rk4_step), e(200, rk4_step))
(1.0703230456058292, 3.9984734943214324)
```

答えを先に決めて問題を作る製造解と，同じ算法を`BigFloat`で実行して丸め誤差を取り除く方法を使う．

## 進め方

[docs/iteration-6.md](docs/iteration-6.md)の手順に従って進める．

1. 準備(6-1)：Iteration 5の模範解答から始まっていることを確かめる．
2. 文法と概念(6-2)：Juliaのノートと理論のノートを読み，REPLで課題を解く．
3. テストリスト(6-3)：要件から`TESTLIST.md`を書く．
4. 設計文書(6-4)：依存図，誤差仕様書を更新し，ADR 0007を書く．
5. テストファーストの実装(6-5)：テストリストの項目を1つずつ実装する．
6. 振り返り(6-6)：模範解答と見比べ，設計文書を実装に合わせる．
7. 発展課題(6-7)：2次のホイン法を加え，同じ基準で次数を確かめる．

終わったら`../solution/`と見比べる．

## ディレクトリの構成

このパッケージは，Iteration 5の模範解答と同じコード，テスト，設計文書から始まる．

```text
Project.toml                         パッケージの名前，UUID，依存(LinearAlgebra)，テスト専用の依存(Random，Test)
src/                                 Iteration 5までのモジュール(ElementaryFunctionsまで)
test/runtests.jl                     テストの入口(unit/integration/exhaustiveのグループ)
test/helpers.jl                      参照解，テストデータ，テスト行列，製造解，誤差予算の上界，シード
test/unit/                           単体テスト
test/integration/                    結合テスト
test/exhaustive/                     局所的な全数検査
design/                              設計文書(Iteration 5の模範解答)
TESTLIST.md                          テストリスト(これから書く)
docs/iteration-6.md                  手順
```
