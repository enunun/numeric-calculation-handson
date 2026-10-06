# Iteration 7：必須のキーワード引数，名前付きタプル，有理数の型

Iteration 7で初めて使うJuliaの文法と機能をまとめる．

## 必須のキーワード引数

`;`の後ろに既定値なしで書いたキーワード引数は，呼び出すときに省略できない．
省略すると`UndefKeywordError`になる．

```julia
julia> g(x; scale) = scale * x;

julia> g(2.0; scale = 3.0)
6.0

julia> g(2.0)
ERROR: UndefKeywordError: keyword argument `scale` not assigned
```

`integrate_adaptive(f, t0, y0, t_end; rtol, atol)`では，rtolとatolを必須にした．
許容誤差は問題に合わせて利用者が決めるもので，既定値を黙って使うと，何を保証したかがわからなくなるからである．

## 名前付きタプル

`(名前 = 値, …)`は名前付きタプルを作る．
フィールドは`r.名前`で取り出せ，ふつうのタプルと同じく位置や分割代入でも取り出せる．

```julia
julia> r = (y = [1.0], accepted = 3, rejected = 1)
(y = [1.0], accepted = 3, rejected = 1)

julia> r.accepted, r[1]
(3, [1.0])

julia> y, accepted, rejected = r;

julia> accepted
3
```

`integrate_adaptive`は`(y = …, accepted = …, rejected = …)`を返す．
構造体(Iteration 3)を定義するほどではない，いくつかの値の組を返すのに使う．

## Rational{BigInt}

`//`で作る有理数は，分子と分母の型が`Int`(64ビット)だと，計算を重ねるとすぐに桁あふれする．
Juliaの有理数は桁あふれを検出して`OverflowError`を投げる．
分子と分母を`BigInt`にすると，桁数に上限がなくなる．

```julia
julia> (1 // 10)^20
ERROR: OverflowError: 10000 * 10000000000000000 overflowed for type Int64

julia> (big(1) // 10)^20
1//100000000000000000000

julia> big(1) // 10 + 1 // 3
13//30
```

`Rational{BigInt}`の値に`Int`の有理数を足すと，結果は`Rational{BigInt}`になる．
`verlet_step`や`rk4_step`は型注釈のない関数なので，有理数の初期値を渡せば，丸め誤差のない計算になる．
ただし，ステップごとに分母の桁数が増えるので，有理数の検査は数ステップから数十ステップにとどめる．

## clamp，cbrt，isfinite

- `clamp(x, lo, hi)`は，xをlo以上hi以下に制限する．
- `cbrt(x)`はxの3乗根である．`x^(1/3)`と違い，`BigFloat`でも定数1/3の丸めが入らない．
- `isfinite(x)`は，xが`Inf`と`NaN`のどちらでもないときに`true`を返す．

```julia
julia> clamp(7.5, 0.2, 5.0), clamp(Inf, 0.2, 5.0)
(5.0, 5.0)

julia> cbrt(1 / 0.0), cbrt(8.0), 0.0^(-1/3)
(Inf, 2.0, Inf)

julia> isfinite(NaN), isfinite(Inf), isfinite(1.0)
(false, false, true)
```

推定が0のときerr^(−1/3)は`Inf`になるが，`clamp`で上限の5に制限される．
解が発散してerrが`NaN`になると，`clamp`は`NaN`を返すので，その場合は`isfinite`で分けて刻み幅を小さくする．

## 要素ごとの最大値

`max.(a, b)`は，ベクトルaとbの要素ごとの最大値を返す(ブロードキャスト，Iteration 2)．

```julia
julia> max.([1.0, -3.0], [2.0, 2.0])
2-element Vector{Float64}:
 2.0
 2.0
```

誤差の尺度atol + rtol·max(|yᵢ|, |y_newᵢ|)は，`atol .+ rtol .* max.(abs.(y), abs.(y_new))`と書ける．
