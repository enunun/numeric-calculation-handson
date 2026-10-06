# Iteration 6の手順：常微分方程式と収束次数

このIterationでは，常微分方程式の初期値問題を解くモジュール`ODESolvers`を作る．
数値解は厳密解と一致しないので，誤差の大きさから正しさを判断するのは難しい．
代わりに，刻み幅を半分にしたときの誤差の減り方(観測次数)を理論次数と比べて検証する．
作業はすべて`iterations/iteration-6/exercise/`で行う．

## 6-1 準備

1. 演習のパッケージを有効にしてREPLを起動し，Pkgモードで`test`を実行する．Iteration 5の模範解答のテストがすべて通る．

   ```text
   Test Summary:  |   Pass   Total   Time
   StableNumerics | 110780  110780  37.3s
        Testing StableNumerics tests passed
   ```

2. リポジトリのルートで，`mise run design iterations/iteration-6/exercise`を実行し，設計文書の検査が通ることを確かめる．

## 6-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-6.md)と[理論のノート](../../../../docs/theory/iteration-6.md)を読み，REPLで次の課題を解く．

1. `apply_twice(h, x) = h(h(x))`を定義し，匿名関数`x -> 2x + 1`と1.0を渡す．
2. y′ = −2y，y(0) = 1をEuler法で区間[0, 1]を10ステップと20ステップで解く関数`euler_decay(n)`をREPLで書き，`exp(-2.0)`と比べる．
3. 課題2の2つの誤差の比から，観測次数log₂(e₁₀/e₂₀)を求める．
4. y′ = 5t⁴，y(0) = 0をRK4で1ステップ(h = 1)進めた値を，シンプソンの公式(0 + 4 × 5 × 0.5⁴ + 5)/6で手計算し，厳密解1との差を求める．
5. 0.0に0.1を10回足した値と，`0.0 + 10 * 0.1`を比べる．
6. `big(0.1)`と`big(1) / 10`を比べ，`BigFloat`で計算するときに`Float64`の定数を書くと何が起きるかを考える．
7. y*(t) = sin t，g(t, y) = −y³として，強制項を加えた右辺fを作る．fは次の式で表される．

   ```text
   f(t, y) = g(t, y) + (cos t − g(t, y*(t)))
   ```

   `f(0.3, sin(0.3)) - cos(0.3)`を求める．

## 6-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 常微分方程式の初期値問題y′ = f(t, y)，y(t₀) = y₀を，一定の刻み幅で数値的に解く．yはベクトルである．
- 1ステップの方法として，Euler法(1次)と古典的な4次のルンゲ＝クッタ法(RK4)を用意する．
- 区間[t₀, t_end]をn等分して解く．tₖはt₀ + k·hで計算する(hを足し続けない)．n < 1なら`ArgumentError`を投げる．
- 要素の型(`Float64`，`BigFloat`)によらず動く．同じ算法を高い精度で実行して，丸め誤差の影響を取り除けるようにする．
- 刻み幅をh，h/2としたときの誤差から観測次数を求め，2つの解からリチャードソン外挿で誤差を推定できる．

### 使用例

```julia
julia> f(t, y) = [y[2], -y[1]];   # 調和振動子(解はcos t，-sin t)

julia> e(n, step) = maximum(abs, integrate(step, f, 0.0, [1.0, 0.0], 2π, n) - [1.0, 0.0]);

julia> e(100, euler_step), e(200, euler_step)
(0.21770684198423074, 0.10367468781049172)

julia> e(100, rk4_step), e(200, rk4_step)
(8.149021641923326e-7, 5.098530393016221e-8)

julia> observed_order(e(100, euler_step), e(200, euler_step)), observed_order(e(100, rk4_step), e(200, rk4_step))
(1.0703230456058292, 3.9984734943214324)
```

### 作るもの

- `ODESolvers`(新規)
  - `euler_step(f, t, y, h)`：y + h·f(t, y)を返す．
  - `rk4_step(f, t, y, h)`：古典的な4次のルンゲ＝クッタ法の1ステップを返す．
  - `integrate(step, f, t0, y0, t_end, n::Integer)`：`step`をn回適用し，t_endでの近似解を返す．
  - `observed_order(error_coarse, error_fine)`：log₂(error_coarse/error_fine)を返す．
  - `richardson_error_estimate(y_coarse, y_fine, p::Integer)`：p次の方法の細かい刻み幅の解の誤差を(y_coarse − y_fine)/(2ᵖ − 1)で推定する．

### 考えること

- 1ステップの値を厳密に確かめられる入力はあるか．RK4が厳密になる右辺は何か．
- 係数を1つ誤ったRK4は，1ステップの値のテストで見つかるか．見つからないなら，何で見つけるか．
- 観測次数が理論次数に「近い」とは，どう判定するか．「|p̂ − p| ≤ 0.1」のような基準の値に根拠はあるか．
- 厳密解のわかる問題をどう作るか．解法の非線形の部分や時刻への依存も使う問題にするには，どうすればよいか．
- 刻み幅を小さくすると丸め誤差がたまる．観測次数を測るときに，丸め誤差の影響をどう取り除くか．取り除けていることをどう確かめるか．
- 厳密解のわからない問題(振り子y″ = −sin y)でも，収束次数を確かめられるか．

## 6-4 設計文書

- `design/modules.md`：`ODESolvers`を加える．
- `design/error-spec.md`：
  - 表の前に，大域誤差e(h)，観測次数p̂，ずれd(h) = |p̂ − p|の定義を書く．
  - `euler_step`，`rk4_step`，`integrate`，`observed_order`，`richardson_error_estimate`の行を加える．誤差界は「大域誤差 ≈ Chᵖ」という漸近的な主張である．
  - 表の下に，観測次数の判定基準とその根拠(漸近展開)，基準を使える範囲(漸近範囲)，丸め誤差が打ち切り誤差に比べて無視できる範囲を書く．
- `design/adr/0007-ode-order-verification.md`(新規)：常微分方程式の解法の正しさを，個々の値ではなく収束次数で検証する理由を書く．1ステップの値を参照解と比べる方法，誤差の大きさに許容誤差を決める方法と比べる．

書いたら`mise run design iterations/iteration-6/exercise`で検査する．

## 6-5 テストファーストの実装

### ODESolvers

- `src/ODESolvers.jl`を作り，`src/StableNumerics.jl`で`include`して，関数を`export`する．
- 引数に型注釈を付けない．定数は`h / 2`，`h / 6`のように整数で割り，`BigFloat`の計算に`Float64`の定数が入らないようにする．
- `integrate`の時刻は`t0 + k * h`で計算する(課題5)．

### テスト

- `test/unit/ode_solvers_tests.jl`を作り，`test/runtests.jl`のグループ`unit`に登録する．
- 1ステップの値は，丸めの起きない入力を使い`==`で確かめる．RK4は，右辺がtだけの3次以下の多項式なら厳密である．
- 製造解は`test/helpers.jl`に置く．y*(t) = (sin t, e⁻ᵗcos 2t)と，非線形の右辺g(t, y) = (−y₁³ + y₂, y₁y₂)を使う．区間は[0, 2]とする．
- 観測次数は，同じ算法を`BigFloat`で実行して測る．精度は`setprecision(BigFloat, 128) do ... end`で128ビットにする．分割数はn = 2³〜2⁹とする．
- 判定基準(hを半分にしたときのずれの比が0.6以下)は，定数`ORDER_DEVIATION_RATIO`として`test/helpers.jl`に置く．
- `Float64`の丸め誤差(`Float64`と`BigFloat`の解の差)が，打ち切り誤差の1%以下であることも確かめる．
- 振り子の検査は`test/integration/ode_convergence_tests.jl`に置く．隣り合う分割数の解の差から観測次数を求める．

### よくある間違い

- 時刻を`t += h`で求める．ステップ数が多いと時刻に丸め誤差がたまる．
- 観測次数の判定基準を，実測した値から決める．根拠を説明できず，刻み幅の範囲を変えると意味が変わる．
- 漸近範囲に入っていない刻み幅で判定する．正しい実装でも基準を満たさないことがある．
- `Float64`で観測次数を測り，丸め誤差が効く刻み幅まで細かくする．次数が見かけ上下がる．

## 6-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．
2. `rk4_step`のk3を`y + h / 2 * k1`で求めるように変えると，どのテストが失敗するか．1ステップの値のテストと，観測次数のテストのどちらで見つかるか(確かめたら元に戻す)．
3. RK4の重みを1/6, 2/6, 2/6, 1/6から1/4ずつに変えると，どのテストが失敗するか．
4. 振り子の検査で，Euler法の分割数をn = 2⁴〜2⁹にすると何が起きるか．なぜか．
5. リチャードソン外挿の推定を誤差の上界として使ってよいか．
6. 設計文書と実装を見比べ，食い違うところを直す．`mise run design iterations/iteration-6/exercise`が通るようにする．

## 6-7 発展課題

2次のホイン法(改良Euler法)`heun_step(f, t, y, h)`を加える．

```text
k₁ = f(t, y)
k₂ = f(t + h, y + h·k₁)
yₖ₊₁ = y + h/2·(k₁ + k₂)
```

製造解の問題で，観測次数のずれが同じ基準を満たすことを確かめる．
テストリスト，設計文書，テストファーストの実装の順に進める．
