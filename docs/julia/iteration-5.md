# Iteration 5：浮動小数点数の操作

Iteration 5で初めて使うJuliaの文法と機能をまとめる．

## 指数部と仮数部

```julia
julia> ldexp(1.5, 3), ldexp(1.0, -1074), ldexp(1.0, -1075)
(12.0, 5.0e-324, 0.0)

julia> exponent(10.0), significand(10.0)
(3, 1.25)

julia> exponent(big(0.75))
-1
```

- `ldexp(y, k)`はy·2ᵏを返す．結果が正規化数なら丸めはない．非正規化数の範囲では丸められ，小さすぎると0になる．
- `exponent(x)`は，|x|が属する区間(2ᵉ以上2ᵉ⁺¹未満)のeを返す．`significand(x)`は仮数(1以上2未満)を返す．`BigFloat`にも使える．
- `floatmax(Float64)`は最大の有限の数，`floatmin(Float64)`は最小の正規化数，`nextfloat(0.0)`は最小の非正規化数である．`issubnormal(x)`は，xが非正規化数かどうかを調べる．

```julia
julia> floatmax(Float64), floatmin(Float64), nextfloat(0.0)
(1.7976931348623157e308, 2.2250738585072014e-308, 5.0e-324)

julia> log(floatmax(Float64)), log(floatmin(Float64))
(709.782712893384, -708.3964185322641)
```

exp(x)は，xが約709.78を超えるとオーバーフローし，約−708.40より小さいと非正規化数になる．

## 整数への丸め

`round(Int, x)`は，xを最も近い整数に丸めて`Int`で返す．ちょうど中間の値は偶数に丸める．

```julia
julia> round(Int, 2.5), round(Int, 3.5), round(Int, -0.7)
(2, 4, -1)
```

## 多項式の評価

`evalpoly(x, (a₀, a₁, …, aₙ))`は，多項式a₀ + a₁x + ⋯ + aₙxⁿをホーナー法で評価する．係数は低い次数から並べる．

```julia
julia> evalpoly(2.0, (1.0, 3.0, 5.0))
27.0
```

1 + 3 × 2 + 5 × 4 = 27である．
係数のタプルは，`Tuple(式 for j in 範囲)`で作れる．
`タプル .|> Float64`は，各要素に`Float64`を適用する(`|>`のブロードキャスト)．

## 連続する浮動小数点数を列挙する

`nextfloat(x)`はxの次の数，`prevfloat(x)`は前の数を返す．`nextfloat(x, k)`はk個先の数を返す．

```julia
julia> [nextfloat(1.0, k) for k in 1:3]
3-element Vector{Float64}:
 1.0000000000000002
 1.0000000000000004
 1.0000000000000007
```

局所的な全数検査では，この関数で中心の前後の数を順に作る．

## ビット列を見る

`bitstring(x)`は，浮動小数点数のビット列を文字列で返す．先頭から符号1ビット，指数11ビット，仮数52ビットである．
`reinterpret(UInt64, x)`は，同じビット列を符号なし整数として読み直す．

```julia
julia> bitstring(1.0)
"0011111111110000000000000000000000000000000000000000000000000000"

julia> reinterpret(UInt64, 1.0)
0x3ff0000000000000
```

`trailing_zeros(reinterpret(UInt64, x))`で，仮数の下位に並ぶ0のビットの数を数えられる．
Cody–Waiteの方法のLN2_HIでは21になる．

## テストのグループを分ける

`test/runtests.jl`の`GROUPS`に`"exhaustive"`を加え，時間のかかる検査を`test/exhaustive/`に置く．

```julia
const GROUPS = isempty(ARGS) ? ["unit", "integration", "exhaustive"] : ARGS
```

```julia
julia> using Pkg

julia> Pkg.test(test_args = ["exhaustive"])
```

このように実行すると，局所的な全数検査だけが実行される．
`Pkg.test(test_args = ["unit", "integration"])`なら，全数検査を除いて実行できる．
