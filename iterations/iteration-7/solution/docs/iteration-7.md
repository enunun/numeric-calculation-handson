# Iteration 7の解説：刻み幅の自動調整とシンプレクティック法

演習の手順と同じ番号で，各手順の模範解答と考え方を説明する．

## 7-1 準備

演習のパッケージは，Iteration 6の模範解答と同じコード，テスト，設計文書から始まる．
110827件のテストがすべて通り，設計文書の検査も通る状態が出発点である．

## 7-2 文法と概念

1. 既定値のないキーワード引数は省略できない．

   ```julia
   julia> g(x; scale) = scale * x;

   julia> g(2.0; scale = 3.0)
   6.0

   julia> g(2.0)
   ERROR: UndefKeywordError: keyword argument `scale` not assigned
   ```

2. 名前と位置のどちらでも取り出せる．

   ```julia
   julia> r = (y = [1.0], accepted = 3, rejected = 1)
   (y = [1.0], accepted = 3, rejected = 1)

   julia> r.accepted, r[1]
   (3, [1.0])
   ```

3. `Int`の有理数は桁あふれし，`BigInt`の有理数は正しく計算できる．

   ```julia
   julia> (1 // 10)^20
   ERROR: OverflowError: 10000 * 10000000000000000 overflowed for type Int64

   julia> (big(1) // 10)^20
   1//100000000000000000000
   ```

4. どちらの解も重みの和が1なので，y′ = 定数の問題を厳密に解く(1次の条件)．推定の係数の和が0なので，傾きがすべて同じなら推定は0になる．

   ```julia
   julia> (2 + 3 + 4) // 9, (7 + 6 + 8 + 3) // 24, -5 + 6 + 8 - 9
   (1//1, 1//1, 0)
   ```

5. q = 7/8，p = −15/32になる．

   ```julia
   julia> h = 1 // 2; q, p = 1 // 1, 0 // 1;

   julia> p_half = p + h / 2 * (-q); q_new = q + h * p_half; p_new = p_half + h / 2 * (-q_new); (q_new, p_new)
   (7//8, -15//32)
   ```

6. 修正エネルギーは厳密に等しく，エネルギーは1/2から1009/2048に減る．差−15/2048は，h²(q² − 1)/8 = (1/32)(49/64 − 1)に等しい．

   ```julia
   julia> (p^2 + (1 - h^2 / 4) * q^2) / 2, (p_new^2 + (1 - h^2 / 4) * q_new^2) / 2
   (15//32, 15//32)

   julia> (p^2 + q^2) / 2, (p_new^2 + q_new^2) / 2
   (1//2, 1009//2048)
   ```

7. 等しい．

   ```julia
   julia> h = big(1) // 10; (1 - h^2 / 2 + h^4 / 24)^2 + (h - h^3 / 6)^2 == 1 - h^6 / 72 + h^8 / 576
   true
   ```

## 7-3 テストリスト

模範解答は[TESTLIST.md](../TESTLIST.md)にある．
項目を選ぶときに考えたことを説明する．

### 保証されることだけをテストする

rtolとatolは局所誤差の目標で，大域誤差はtol以下になるとは限らない．
製造解の問題では，大域誤差はtolの約3.5〜3.9倍だった．
「大域誤差 ≤ tol」をテストに書くと，この問題では不合格になり，別の問題では合格するという，根拠のないテストになる．
代わりに，理論から導ける「tolを小さくすると大域誤差が減り，ステップ数が増える」という関係を検査する．
テストしない性質は，リストに「テストしない」と書いて残した．

### 正確な値で確かめられる振る舞い

推定が0なら倍率は上限の5になる．この性質を使うと，ステップ数を正確に予想できる．
y′ = 2tでは推定が0なので，区間[0, 2]の刻み幅は0.02，0.1，0.5と5倍ずつ増え，最後は残りの1.38に縮める．受理は4回，棄却は0回である．
この1つの項目で，最初の刻み幅，倍率の上限，最後のステップの扱いを確かめられる．

### 丸め誤差のない計算で厳密に確かめる

Störmer–Verlet法が保つ量(修正エネルギー，中心力の角運動量)と時間の反転は，丸め誤差がなければ厳密に成り立つ．
`Rational{BigInt}`で計算すれば，`==`で検査できる．
中心力にはF(q) = −|q|²qを使った．有理数の範囲で計算でき，調和振動子と違って非線形である．

### 長い時間の検査の許容誤差を導く

`Float64`の保存量は，丸め誤差の分だけ変わる．
1ステップの変化の上界を標準モデルで導き(誤差仕様書)，nステップ分を許容誤差にした．
保存量を`Float64`で評価すると評価の丸め誤差が混ざるので，`BigFloat`で評価する．

## 7-4 設計文書

### design/modules.md

`Hamiltonian`を加えた．ほかのモジュールを使わないので，`StableNumerics`からの矢印だけである．

### design/error-spec.md

- 表の前に，tol，H，H̃，Lの定義を加えた．
- `bs32_step`，`integrate_adaptive`，`verlet_step`，`verlet_integrate`の行を加えた．
- 表の下に，「刻み幅の自動調整の許容誤差」と「Störmer–Verlet法の保存量の誤差界の導き方」の節を加えた．後者では，1ステップの各成分の丸め誤差を順にたどり，修正エネルギーは6u，角運動量は12u以下しか変わらないことを導いた．実測の値も書いた．

### design/adr/0008-adaptive-and-symplectic.md

刻み幅の制御にBogacki–Shampineの組を，長時間の計算にStörmer–Verlet法を使うことを決めた．
刻み幅を2つで解く方法，Dormand–Princeの組，FSAL，RK4で刻み幅を小さくする方法と比べた．

## 7-5 テストファーストの実装

### 最初の失敗

4つの関数を，`error`を投げるだけにしてテストを実行する．

```text
bs32_step: Error During Test at …/test/unit/ode_solvers_tests.jl:81
  Test threw exception
  Expression: bs32_step(((t, y)->begin
                #= …/test/unit/ode_solvers_tests.jl:81 =#
                [3 * t ^ 2]
            end), 0.0, [0.0], 1.0) == ([1.0], [-0.125])
```

```text
integrate_adaptive: Test Failed at …/test/unit/ode_solvers_tests.jl:107
  Expression: integrate_adaptive(f, 0.0, [1.0, 0.0], 1.0; rtol = 0.0, atol = 1.0e-6)
    Expected: ArgumentError
      Thrown: ErrorException
      integrate_adaptiveは未実装
```

最初は，発散する問題の項目を`@test_throws ErrorException`で書いていた．
未実装の`error`も`ErrorException`を投げるので，この項目は実装する前から合格してしまう．
Redにならないテストは，何も確かめていない．
例外のメッセージ「刻み幅が小さくなりすぎた」を`@test_throws`に渡して確かめるように直した．

### bs32_step

```julia
function bs32_step(f, t, y, h)
    k1 = f(t, y)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + 3h / 4, y + 3h / 4 * k2)
    y_new = y + h / 9 * (2k1 + 3k2 + 4k3)
    k4 = f(t + h, y_new)
    error_estimate = h / 72 * (-5k1 + 6k2 + 8k3 - 9k4)
    return (y_new, error_estimate)
end
```

### integrate_adaptive

```julia
function integrate_adaptive(f, t0, y0, t_end; rtol, atol)
    rtol > 0 || throw(ArgumentError("rtolは正でなければならない(rtol = $(rtol))"))
    atol > 0 || throw(ArgumentError("atolは正でなければならない(atol = $(atol))"))
    t_end > t0 || throw(ArgumentError("t_endはt0より大きくなければならない(t0 = $(t0)，t_end = $(t_end))"))
    t = t0
    y = y0
    h = (t_end - t0) / 100
    accepted = 0
    rejected = 0
    while t < t_end
        last_step = h >= t_end - t
        if last_step
            h = t_end - t
        end
        t + h > t || error("刻み幅が小さくなりすぎた(t = $(t)，h = $(h))")
        y_new, error_estimate = bs32_step(f, t, y, h)
        scale = atol .+ rtol .* max.(abs.(y), abs.(y_new))
        err = sqrt(sum(abs2, error_estimate ./ scale) / length(y))
        if err <= 1
            t = last_step ? t_end : t + h
            y = y_new
            accepted += 1
        else
            rejected += 1
        end
        factor = isfinite(err) ? clamp(9 * cbrt(1 / err) / 10, 1 / 5, 5) : 1 / 5
        h *= factor
    end
    return (y = y, accepted = accepted, rejected = rejected)
end
```

解が発散するとerrが`Inf`や`NaN`になる．`clamp`は`NaN`をそのまま返すので，`isfinite`で分けて刻み幅を1/5にする．

### Hamiltonian

```julia
function verlet_step(force, q, p, h)
    p_half = p + h / 2 * force(q)
    q_new = q + h * p_half
    p_new = p_half + h / 2 * force(q_new)
    return (q_new, p_new)
end

function verlet_integrate(force, q0, p0, h, n::Integer)
    n >= 0 || throw(ArgumentError("ステップ数nは0以上でなければならない(n = $(n))"))
    q, p = q0, p0
    for _ in 1:n
        q, p = verlet_step(force, q, p, h)
    end
    return (q, p)
end
```

### 保存量のテスト

`Float64`で10⁴ステップ解き，保存量を`BigFloat`で評価して，誤差仕様書の上界と比べる．

```julia
h, n = 0.1, 10^4
q, p = verlet_integrate(harmonic_force, [1.0], [0.0], h, n)
modified_drift = abs(modified_energy(big.(q), big.(p), big(h)) - modified_energy([big(1.0)], [big(0.0)], big(h)))
rounding = gamma(VERLET_MODIFIED_ENERGY_ROUNDING * n, Float64)
@test modified_drift <= rounding
@test abs(energy(big.(q), big.(p)) - big(1) / 2) <= big(h)^2 / 8 + 2rounding
```

10⁶ステップの検査は，同じ許容誤差で，すべてのステップの最大値を調べる．
実測は，修正エネルギーの変化が1.1 × 10⁻¹³(上界6.7 × 10⁻¹⁰)，角運動量の変化が2.0 × 10⁻¹³(上界1.3 × 10⁻⁹)だった．
エネルギーの誤差の最大値は0.0012499999999398で，上界h²/8にほぼ達する．
h²/8は誤差を大きめに見積もった値ではなく，到達する値である．

### 間違った実装を見つけられるか

| 間違い | 不合格になったテスト |
| --- | --- |
| `p_half`を`p + h * force(q)`にする | `verlet_step`(2件)，修正エネルギーと時間の反転(有理数，2件)，次数(5件)，`Float64`の修正エネルギーとエネルギー(10⁴ステップ，10⁶ステップで各2件) |
| `p_new`の力を`force(q)`で求める | `verlet_step`(2件)，有理数の3件すべて，次数(5件)，`Float64`の保存量(10⁴ステップで3件，10⁶ステップで3件)，ケプラー問題 |
| 推定の係数`-9k4`を`-8k4`にする | `bs32_step`(2件)，推定の次数(5件)，ステップ数の項目，大域誤差の単調性(2件) |
| 刻み幅の倍率の`cbrt`を`sqrt`にする | なし |

`p_half`の間違いは，ずらしの合成なのでシンプレクティックで，中心力の角運動量も保つ．
そのため，角運動量の検査とケプラー問題の検査は通る．
保存量の検査だけでは見つからない間違いがあり，次数の検査と組み合わせる必要がある．

`-8k4`の間違いでは，推定が1次の大きさになり，観測次数のずれが2に近づく．
刻み幅が必要以上に小さくなるので，tol = 10⁻¹⁰の計算に9分以上かかった．

`sqrt`の間違いは，刻み幅の決め方を変えるだけで，受理するステップは誤差の目標を満たしている．
効率は変わるが，結果の正しさの主張は変わらないので，テストが失敗しないのは問題ではない．

## 7-6 振り返り

1. 模範解答のリストには，テストしない性質(大域誤差 ≤ tol)の記録と，有理数で厳密に確かめる項目が含まれている．
2. 上の表のとおりである．角運動量とケプラー問題の検査は失敗しない．間違えた方法もシンプレクティックで，中心力の角運動量を保つからである．
3. 上の表のとおりである．シンプレクティックでなくなり，エネルギーが時間とともに変わるので，ケプラー問題の検査も失敗する．
4. どのテストも失敗しない．刻み幅の倍率は効率に関わるが，受理の条件(err ≤ 1)は変わらないので，問題ではない．
5. 大域誤差は，どのtolでもtolの約3.5〜3.9倍で，tolにほぼ比例する．大域誤差がtolの何倍になるかは問題によって違う．
6. 模範解答では，設計文書と実装は一致している．`mise run design iterations/iteration-7/solution`で確かめられる．

## 7-7 発展課題

FSALを使う解答例を示す．
1ステップの関数は，前のステップのk₄をk₁として受け取り，新しいk₄も返す．

```julia
function bs32_step_fsal(f, t, y, h, k1)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + 3h / 4, y + 3h / 4 * k2)
    y_new = y + h / 9 * (2k1 + 3k2 + 4k3)
    k4 = f(t + h, y_new)
    error_estimate = h / 72 * (-5k1 + 6k2 + 8k3 - 9k4)
    return (y_new, error_estimate, k4)
end
```

`integrate_adaptive`では，ループの前に`k1 = f(t, y)`を求め，ステップを受理したら`k1 = k4`とする．
棄却したときは，yとtが変わらないので，k₁はそのまま使える．

製造解の問題で，変更の前後の結果は`==`で一致した．
右辺の評価回数は，tol = 10⁻⁴で76回から58回に，tol = 10⁻⁸で1308回から982回に減った．
変更前は1回の試み(受理または棄却)ごとに4回，変更後は最初の1回と1回の試みごとに3回評価する．

結果が1ビットも変わらないはずの変更では，許容誤差のない`==`で前後を比べられる．
これは，Iteration 4のリファクタリングの安全網と同じ考え方である．
