# Iteration 6の解説：常微分方程式と収束次数

演習の手順と同じ番号で，各手順の模範解答と考え方を説明する．

## 6-1 準備

演習のパッケージは，Iteration 5の模範解答と同じコード，テスト，設計文書から始まる．
110780件のテストがすべて通り，設計文書の検査も通る状態が出発点である．

## 6-2 文法と概念

1. 2x + 1を2回適用するので，1.0 → 3.0 → 7.0となる．

   ```julia
   julia> apply_twice(h, x) = h(h(x));

   julia> apply_twice(x -> 2x + 1, 1.0)
   7.0
   ```

2. Euler法の1ステップはy(1 − 2h)を掛けることなので，結果は(1 − 2/n)のn乗である．

   ```julia
   julia> euler_decay(n) = (y = 1.0; h = 1.0 / n; for k in 1:n; y += h * (-2y); end; y);

   julia> euler_decay(10), euler_decay(20), exp(-2.0)
   (0.10737418240000003, 0.12157665459056928, 0.1353352832366127)
   ```

3. 観測次数は1に近い．

   ```julia
   julia> e10, e20 = abs(euler_decay(10) - exp(-2.0)), abs(euler_decay(20) - exp(-2.0))
   (0.02796110083661267, 0.013758628646043422)

   julia> log2(e10 / e20)
   1.0230844806573423
   ```

4. 右辺がtだけなら，RK4のk₂とk₃は同じ値になり，シンプソンの公式と一致する．差は1/24 ≈ 0.0417である．

   ```julia
   julia> (0 + 4 * 5 * 0.5^4 + 5) / 6
   1.0416666666666667
   ```

5. 足し続けると，0.1の表現誤差がたまって1.0にならない．`0.0 + 10 * 0.1`では1回だけ丸めるので1.0になる．

   ```julia
   julia> add_steps(n, h) = (t = 0.0; for k in 1:n; t += h; end; t);

   julia> add_steps(10, 0.1), 0.0 + 10 * 0.1
   (0.9999999999999999, 1.0)
   ```

6. `big(0.1)`は，`Float64`の0.1(2進数に丸めた値)を`BigFloat`に変換したもので，17桁目から1/10と違う．`BigFloat`で計算する式に`0.1`と書くと，`Float64`の精度の誤差が入る．

   ```julia
   julia> big(0.1), big(1) / 10
   (0.1000000000000000055511151231257827021181583404541015625, 0.1000000000000000000000000000000000000000000000000000000000000000000000000000002)
   ```

7. 強制項がg(t, y*(t))を打ち消すので，f(t, y*(t)) = cos t = y*′(t)となる．この点では丸め誤差も打ち消し合って0になった．

   ```julia
   julia> ystar(t) = sin(t); g(t, y) = -y^3; f(t, y) = g(t, y) + (cos(t) - g(t, ystar(t)));

   julia> f(0.3, ystar(0.3)) - cos(0.3)
   0.0
   ```

## 6-3 テストリスト

模範解答は[TESTLIST.md](../TESTLIST.md)にある．
項目を選ぶときに考えたことを説明する．

### 1ステップの値と収束次数を分ける

1ステップの値を厳密に確かめられるのは，丸めが起きない入力と，RK4が厳密になる右辺(tだけの3次以下の多項式)だけである．
これらのテストは，引数の順序や重みの取り違えのような単純な間違いを見つける．
係数の誤りは，テイラー展開の低次の項を変えないことが多く，1ステップの値では見つからない(6-6の2)．
そこで，解法の正しさの中心は観測次数で確かめる．

### 判定基準は漸近展開から決める

観測次数のずれ|p̂ − p|は，hにほぼ比例する(理論のノートの4節)．
「hを半分にしたときのずれの比が0.6以下」という基準は，理論の比1/2に高次の項の分の余裕を加えたものである．次数の誤った実装では，ずれが一定の値に近づくので満たせない．
基準の値は`ORDER_DEVIATION_RATIO`として`test/helpers.jl`に置き，根拠を誤差仕様書に書いた．

### 丸め誤差と打ち切り誤差を分ける

観測次数は，同じ算法を`BigFloat`(128ビット)で実行して測る．
それとは別に，`Float64`で実行した結果と`BigFloat`の結果の差(丸め誤差)が打ち切り誤差の1%以下であることを確かめる．
これで，同じ刻み幅の範囲なら`Float64`で測っても観測次数がほぼ変わらないこと(影響は0.015以下)がわかる．

### 厳密解を使わない検査

振り子のように厳密解がわからない問題では，隣り合う刻み幅の解の差から観測次数を求める．
この検査は公開APIだけを使うので，結合テストに置いた．

## 6-4 設計文書

### design/modules.md

`ODESolvers`を加えた．ほかのモジュールを使わないので，`StableNumerics`からの矢印だけである．

### design/error-spec.md

- 表の前に，大域誤差e(h)，観測次数p̂，ずれd(h)の定義を加えた．
- `euler_step`，`rk4_step`，`integrate`，`observed_order`，`richardson_error_estimate`の行を加えた．
- 表の下に，「常微分方程式の解法の検証の基準」の節を加えた．漸近展開からp̂ = p + Dh/(2 ln 2) + O(h²)を導き，判定基準0.6，漸近範囲の前提，`BigFloat`で打ち切り誤差を測ることと丸め誤差の1%の条件を書いた．

### design/adr/0007-ode-order-verification.md

解法の正しさを観測次数で検証することを決めた．
1ステップの値を参照解と比べる方法(係数の誤りを見つけられない)，誤差の大きさに許容誤差を決める方法(定数Cが問題ごとに違い，根拠のある値を決められない)と比べた．

## 6-5 テストファーストの実装

### 最初の失敗

`src/ODESolvers.jl`に，`error`を投げるだけの関数を置いてテストを実行すると，`ODESolvers`のテストがすべて失敗する．

```text
euler_step: Error During Test at …/test/unit/ode_solvers_tests.jl:6
  Test threw exception
  Expression: euler_step(((t, y)->begin
                #= …/test/unit/ode_solvers_tests.jl:6 =#
                [1.0, t]
            end), 0.5, [1.0, 2.0], 0.5) == [1.5, 2.25]
  euler_stepは未実装
```

```text
    ODESolvers                              |            1     16      17   4.6s
      euler_step                            |                   1       1   1.9s
      rk4_step                              |                   3       3   0.0s
      integrate                             |            1      3       4   2.1s
      observed_order                        |                   2       2   0.0s
      richardson_error_estimate             |                   2       2   0.0s
      収束次数：euler_step                  |                   1       1   0.3s
      収束次数：rk4_step                    |                   1       1   0.1s
      Float64の丸め誤差は打ち切り誤差に比べて小さい：euler_step |                   1       1   0.0s
      Float64の丸め誤差は打ち切り誤差に比べて小さい：rk4_step |                   1       1   0.0s
      リチャードソン外挿の推定は真の誤差に近づく |                   1       1   0.1s
```

`integrate`の`@test_throws ArgumentError`だけは，例外が投げられたが種類が違うので，エラーではなく失敗(Fail)になる．

### ステップの関数

```julia
euler_step(f, t, y, h) = y + h * f(t, y)

function rk4_step(f, t, y, h)
    k1 = f(t, y)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + h / 2, y + h / 2 * k2)
    k4 = f(t + h, y + h * k3)
    return y + h / 6 * (k1 + 2k2 + 2k3 + k4)
end
```

定数は整数で割るので，yとhが`BigFloat`なら計算もすべて`BigFloat`で行われる．

### integrate

```julia
function integrate(step, f, t0, y0, t_end, n::Integer)
    n >= 1 || throw(ArgumentError("分割数nは1以上でなければならない(n = $(n))"))
    h = (t_end - t0) / n
    y = y0
    for k in 0:n-1
        y = step(f, t0 + k * h, y, h)
    end
    return y
end
```

`step`として，`euler_step`と`rk4_step`のどちらでも渡せる．

### observed_orderとrichardson_error_estimate

```julia
observed_order(error_coarse, error_fine) = log2(error_coarse / error_fine)

richardson_error_estimate(y_coarse, y_fine, p::Integer) = (y_coarse - y_fine) / (2^p - 1)
```

### 製造解と収束次数のテスト

`test/helpers.jl`に，製造解の問題と，誤差の列から観測次数のずれを求める関数を置いた．

```julia
manufactured_solution(t) = [sin(t), exp(-t) * cos(2t)]
manufactured_derivative(t) = [cos(t), -exp(-t) * cos(2t) - 2exp(-t) * sin(2t)]
nonlinear_part(t, y) = [-y[1]^3 + y[2], y[1] * y[2]]
manufactured_rhs(t, y) = nonlinear_part(t, y) + (manufactured_derivative(t) - nonlinear_part(t, manufactured_solution(t)))
```

収束次数のテストは，`setprecision(BigFloat, 128) do ... end`の中で誤差の列を求め，隣り合うずれの比を確かめる．

```julia
deviations = setprecision(BigFloat, 128) do
    order_deviations(ode_errors(step, BigFloat, ns), p)
end
for i in 1:length(deviations)-1
    @test deviations[i+1] <= ORDER_DEVIATION_RATIO * deviations[i]
end
```

### 漸近範囲を選ぶ

振り子の結合テストを，最初はEuler法もRK4と同じn = 2⁴〜2⁹で書いたところ，Euler法の検査が失敗した．

```text
厳密解を使わない収束次数の検査：euler_step: Test Failed at …/test/integration/ode_convergence_tests.jl:14
  Expression: deviations[i + 1] <= ORDER_DEVIATION_RATIO * deviations[i]
   Evaluated: 0.011627787515691601 <= 0.0014603116626569878
```

観測次数を並べると，1.84，0.989，1.0024，1.0116となり，ずれは一度0の近くまで小さくなってから増えている．
hが大きい範囲では高次の項が効き，ずれが半分ずつにはならない．
実装の誤りではなく，判定基準の前提(漸近範囲)を満たしていなかったのである．
Euler法はn = 2⁸〜2¹³で検査することにし，理由をテストのコメントに書いた．

### 間違った実装を見つけられるか

| 間違い | 不合格になったテスト |
| --- | --- |
| k₃を`y + h / 2 * k1`で求める | 収束次数(5件)，リチャードソン外挿(5件)，振り子(3件) |
| 重みを1/4ずつにする | `rk4_step`の多項式(2件)，収束次数(5件)，リチャードソン外挿(5件)，振り子(3件) |

k₃の間違いでは，`rk4_step`の1ステップのテストはすべて通る．
右辺がtだけならk₃はyに依存しないので，k₁を使っても結果は変わらないからである．
観測次数は1.93，1.96，…，1.998と2に近づき，2次の方法になっていることがわかる．

## 6-6 振り返り

1. 模範解答のリストには，1ステップの値の項目と観測次数の項目に加え，丸め誤差が打ち切り誤差の1%以下であることを確かめる項目が含まれている．
2. 観測次数のテストだけが失敗する(上の表)．1ステップの値のテストでは見つからない．
3. 多項式の厳密さのテストも失敗する．重みの和は1のままなので1次の項は合うが，シンプソンの公式ではなくなる．
4. Euler法の検査が失敗する．n = 2⁷までは漸近範囲に入っておらず，ずれが半分ずつにならない(6-5)．
5. 使えない．推定は誤差の主要な項だけに基づくので，誤差の大きさの目安であり，保証ではない．理論のノートの7節のように，成分によっては推定が合わないこともある．
6. 模範解答では，設計文書と実装は一致している．`mise run design iterations/iteration-6/solution`で確かめられる．

## 6-7 発展課題

ホイン法の解答例を示す．

```julia
function heun_step(f, t, y, h)
    k1 = f(t, y)
    k2 = f(t + h, y + h * k1)
    return y + h / 2 * (k1 + k2)
end
```

製造解の問題で，`BigFloat`(128ビット)，n = 2³〜2⁹で観測次数のずれの比を求めると，0.57，0.51，0.50，0.50，0.50となり，基準を満たす．
テストは，収束次数の`@testset`の組に`("heun_step", heun_step, 2)`を加えるだけでよい．
誤差仕様書には`heun_step`の行(大域誤差O(h²))を加える．
