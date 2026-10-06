# Iteration 7の手順：刻み幅の自動調整とシンプレクティック法

このIterationでは，局所誤差の推定から刻み幅を自動で決める`integrate_adaptive`と，ハミルトン系を解くStörmer–Verlet法を作る．
刻み幅の制御では，許容誤差が保証することと保証しないことを分け，保証されることだけをテストする．
長い時間の計算は，参照解の代わりに保存量で検査し，その許容誤差を丸め誤差の解析から導く．
作業はすべて`iterations/iteration-7/exercise/`で行う．

## 7-1 準備

1. 演習のパッケージを有効にしてREPLを起動し，Pkgモードで`test`を実行する．Iteration 6の模範解答のテストがすべて通る．

   ```text
   Test Summary:  |   Pass   Total   Time
   StableNumerics | 110827  110827  37.0s
        Testing StableNumerics tests passed
   ```

2. リポジトリのルートで，`mise run design iterations/iteration-7/exercise`を実行し，設計文書の検査が通ることを確かめる．

## 7-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-7.md)と[理論のノート](../../../../docs/theory/iteration-7.md)を読み，REPLで次の課題を解く．

1. 必須のキーワード引数を持つ関数`g(x; scale) = scale * x`を定義し，`g(2.0; scale = 3.0)`と`g(2.0)`を実行する．
2. 名前付きタプル`r = (y = [1.0], accepted = 3, rejected = 1)`から，`r.accepted`と`r[1]`を取り出す．
3. `(1 // 10)^20`と`(big(1) // 10)^20`を比べる．
4. Bogacki–Shampineの係数について，3次の解の重みの和(2 + 3 + 4)/9，2次の解の重みの和(7 + 6 + 8 + 3)/24，推定の係数の和−5 + 6 + 8 − 9を有理数で求める．
5. 調和振動子q″ = −qを，q = 1，p = 0，h = 1/2から1ステップ進める．Störmer–Verlet法の3つの式を，有理数を使って手で計算する．
6. 課題5の前後で，修正エネルギー(p² + (1 − h²/4)q²)/2とエネルギー(p² + q²)/2を比べる．
7. h = 1/10(`Rational{BigInt}`)について，RK4の|R(ih)|² = (1 − h²/2 + h⁴/24)² + (h − h³/6)²が1 − h⁶/72 + h⁸/576と等しいことを確かめる．

## 7-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 局所誤差の推定から刻み幅を自動で調整して解く．埋め込みルンゲ＝クッタ法(Bogacki–Shampineの3(2)次の組)を使い，許容誤差rtol，atolを指定する．受理したステップと棄却したステップの数も返す．
- ハミルトン系q″ = F(q)(F(q) = −∇V(q))を，Störmer–Verlet法で解く．qとpはベクトルである．
- Störmer–Verlet法は，時間を反転すると元に戻る(h → −hで逆向きに解ける)．

### 使用例

```julia
julia> f(t, y) = [y[2], -y[1]];

julia> y, accepted, rejected = integrate_adaptive(f, 0.0, [1.0, 0.0], 2π; rtol = 1e-8, atol = 1e-8);

julia> maximum(abs, y - [1.0, 0.0]), accepted, rejected   # 大域誤差は許容誤差より大きい
(1.8317103522846878e-7, 712, 2)

julia> force(q) = -q;   # 調和振動子

julia> q, p = verlet_integrate(force, [1.0], [0.0], 0.1, 1_000_000);   # 10⁶ステップ

julia> (p[1]^2 + q[1]^2) / 2 - 0.5, 0.1^2 / 8   # エネルギーの誤差はh²/8以下にとどまる
(-0.0006895751329086819, 0.0012500000000000002)
```

### 作るもの

- `ODESolvers`
  - `bs32_step(f, t, y, h)`：Bogacki–Shampineの3次の解と，2次の解との差(局所誤差の推定)を`(y_new, error_estimate)`で返す．
  - `integrate_adaptive(f, t0, y0, t_end; rtol, atol)`：`(y = …, accepted = …, rejected = …)`を返す．rtolとatolは省略できない．
- `Hamiltonian`(新規)
  - `verlet_step(force, q, p, h)`：`(q_new, p_new)`を返す．
  - `verlet_integrate(force, q0, p0, h, n::Integer)`：`verlet_step`をn回適用して`(q, p)`を返す．

### 考えること

- 大域誤差がtol以下になることは保証されるか．保証されないなら，tolと大域誤差のどんな関係ならテストできるか．
- `integrate_adaptive`の振る舞いのうち，正確な値で確かめられるものはあるか．推定が0になる右辺では，刻み幅はどう変わるか．
- 解が発散する問題を渡すと何が起きるべきか．
- 丸め誤差のない計算で，Störmer–Verlet法が厳密に保つ量は何か．どうすれば丸め誤差なしに確かめられるか．
- `Float64`で長い時間解くと，保存量は丸め誤差でどれだけ変わりうるか．許容誤差をどう導くか．
- 厳密解も保存量の上界もわからない問題(ケプラー問題)では，何を検査できるか．

## 7-4 設計文書

- `design/modules.md`：`Hamiltonian`を加える．
- `design/error-spec.md`：
  - 表の前に，tol，エネルギーH，修正エネルギーH̃，角運動量Lの定義を書く．
  - `bs32_step`，`integrate_adaptive`，`verlet_step`，`verlet_integrate`の行を加える．`integrate_adaptive`のrtolは局所誤差の目標で，大域誤差の上界ではないことを書く．
  - 表の下に，刻み幅の自動調整で検査すること(とテストしないこと)と，Störmer–Verlet法の保存量の丸め誤差の上界の導き方を書く．
- `design/adr/0008-adaptive-and-symplectic.md`(新規)：刻み幅の制御の方法と，長時間の計算にシンプレクティック法を使う理由を書く．

書いたら`mise run design iterations/iteration-7/exercise`で検査する．

## 7-5 テストファーストの実装

### ODESolvers

- `bs32_step`の推定は，y₃ − y₂を引き算で求めず，係数をまとめたh(−5k₁ + 6k₂ + 8k₃ − 9k₄)/72で求める．
- `3h / 4`のように整数の定数で書き，`BigFloat`の計算に`Float64`の定数が入らないようにする．
- `integrate_adaptive`の最初の刻み幅は(t_end − t0)/100とする．誤差の尺度と次の刻み幅の式は，[理論のノート](../../../../docs/theory/iteration-7.md)の2節に従う．
- 最後のステップでは，時刻にt_endを代入する．
- 時刻が進まなくなったら(t + h == t)，`error`で止める．

### Hamiltonian

- `src/Hamiltonian.jl`を作り，`src/StableNumerics.jl`で`include`して，関数を`export`する．
- `verlet_integrate`はn = 0なら初期値を返し，n < 0なら`ArgumentError`を投げる．

### テスト

- `test/unit/hamiltonian_tests.jl`を作り，グループ`unit`に登録する．
- 厳密に保たれる量は，`Rational{BigInt}`の初期値で数ステップから数十ステップ解き，`==`で確かめる．
- 修正エネルギー，エネルギー，角運動量を求める関数と，丸め誤差の上界の係数は`test/helpers.jl`に置く．
- `Float64`で解いた結果の保存量は，`BigFloat`で評価する．
- 10⁶ステップの検査は`test/exhaustive/hamiltonian_exhaustive_tests.jl`に置き，グループ`exhaustive`に加える．
- ケプラー問題の検査は`test/integration/hamiltonian_conservation_tests.jl`に置く．

### よくある間違い

- 「大域誤差 ≤ tol」をテストする．問題によっては正しい実装でも不合格になる．
- `@test_throws ErrorException`だけで止まることを確かめる．未実装の`error`でも合格してしまう．
- 保存量を`Float64`で評価する．評価の丸め誤差が混ざり，許容誤差の根拠が崩れる．
- 有理数を`Int`で作る．数ステップで桁あふれする．

## 7-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．
2. `verlet_step`の`p_half`を`p + h * force(q)`に変えると，どのテストが失敗するか．角運動量の検査とケプラー問題の検査は失敗するか．なぜか(確かめたら元に戻す)．
3. `p_new`を`p_half + h / 2 * force(q)`に変えると，どのテストが失敗するか．
4. 刻み幅の倍率の`cbrt`を`sqrt`に変えると，どのテストが失敗するか．失敗しないなら，それは問題か．
5. tolを10⁻³から10⁻¹⁰まで変えたとき，大域誤差とtolの比はどうなるか．
6. 設計文書と実装を見比べ，食い違うところを直す．`mise run design iterations/iteration-7/exercise`が通るようにする．

## 7-7 発展課題

Bogacki–Shampine法では，受理したステップのk₄ = f(t + h, y₃)が，次のステップのk₁と同じ値になる(FSAL：First Same As Last)．
これを使って，1ステップあたりの右辺の評価を4回から3回に減らす．

- 変更の前後で，`integrate_adaptive`の結果が`==`で一致することを確かめる．同じ値を使い回すだけなので，結果は1ビットも変わらないはずである．
- 右辺の評価回数を数える関数を作り，評価が減ったことを確かめる．
