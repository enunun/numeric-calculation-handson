# Iteration 1：fma，nothing，BigFloat，多重ディスパッチ

Iteration 1で初めて使うJuliaの文法と機能をまとめる．

## 数値の関数

```julia
julia> fma(2.0, 3.0, 1.0)
7.0

julia> sqrt(2.0), sqrt(4.0)
(1.4142135623730951, 2.0)

julia> isfinite(1.0), isfinite(Inf), isfinite(NaN)
(true, false, false)

julia> minmax(3.0, 1.0)
(1.0, 3.0)

julia> copysign(3.0, -0.0), copysign(3.0, 0.0)
(-3.0, 3.0)
```

- `fma(a, b, c)`はa × b + cを1回だけ丸めて計算する(融合積和演算)．
- `sqrt(x)`は平方根を返す．負の実数を渡すと`DomainError`を投げる．
- `isfinite(x)`は，xが`Inf`，`-Inf`，`NaN`のどれでもないときに`true`を返す．`isnan(x)`は`NaN`かどうかを調べる．
- `minmax(x, y)`は，小さい方と大きい方の組を返す．
- `copysign(x, y)`は，絶対値がxで符号がyの数を返す．yの符号は−0.0のような0の符号も含む．

## nothingとUnion

`nothing`は「値がない」ことを表す値である．
`isnothing(x)`または`x === nothing`で調べる．`===`は「同じものか」を調べる比較である．

```julia
julia> x = nothing

julia> isnothing(x), x === nothing
(true, true)

julia> positive_part(x::Float64) = x > 0 ? x : nothing
positive_part (generic function with 1 method)

julia> positive_part(2.0), positive_part(-1.0)
(2.0, nothing)
```

REPLは`nothing`を返す式の結果を表示しない．
`positive_part`の戻り値の型は`Union{Nothing, Float64}`，つまり「`nothing`または`Float64`」である．
`quadratic_roots`は，実根がなければ`nothing`，あれば根の組を返すので，戻り値の型は`Union{Nothing, Tuple{T, T}}`である．
呼び出す側は，結果を使う前に`isnothing`で調べる．

## BigFloat

`BigFloat`は，精度(仮数のビット数)を自由に選べる浮動小数点数である．既定の精度は256ビットである．

```julia
julia> precision(BigFloat)
256

julia> big(0.1)
0.1000000000000000055511151231257827021181583404541015625

julia> BigFloat(1) / 3
0.3333333333333333333333333333333333333333333333333333333333333333333333333333348

julia> setprecision(BigFloat, 64) do
           BigFloat(1) / 3
       end
0.333333333333333333342
```

- `big(x)`は，`Float64`のxを`BigFloat`に変換する．変換は厳密で，倍精度の0.1が実際に表している値がすべて表示される．
- `BigFloat`の計算も丸めを含む．256ビットの精度なら，1回の演算の相対誤差は2⁻²⁵⁶程度である．
- `setprecision(BigFloat, p) do ... end`は，ブロックの中だけ精度をpビットにする．ブロックの外の精度は変わらない．

## doブロック

`f(x) do 引数 ... end`は，`do`から`end`までを無名関数にして，`f`の最初の引数として渡す書き方である．
`setprecision(BigFloat, 64) do ... end`は，「精度64ビットで実行する処理」を関数として`setprecision`に渡している．

```julia
julia> map((1, 2, 3)) do k
           k^2
       end
(1, 4, 9)
```

これは`map(k -> k^2, (1, 2, 3))`と同じである．`k -> k^2`は，引数kを受け取ってk²を返す無名関数である．

## 関数のドット呼び出し

`f.(x)`は，タプルやベクトルxの各要素にfを適用する．

```julia
julia> Rational{BigInt}.((0.5, 0.25))
(1//2, 1//4)
```

`A, B, C, R = Rational{BigInt}.((a, b, c, r))`のように，複数の値をまとめて変換するのに使う．
Iteration 2では，演算子のドット呼び出し(`.+`など)を含めて，この仕組み(ブロードキャスト)を詳しく扱う．

## 多重ディスパッチ

Juliaの関数は，引数の型の組み合わせごとに別の実装(メソッド)を持てる．
呼び出すときは，すべての引数の型を見て，最も特定的なメソッドが選ばれる．これを多重ディスパッチと呼ぶ．

```julia
julia> describe(x::Integer) = "整数"
describe (generic function with 1 method)

julia> describe(x::AbstractFloat) = "浮動小数点数"
describe (generic function with 2 methods)

julia> describe(1), describe(1.0)
("整数", "浮動小数点数")
```

`methods(describe)`で，関数が持つメソッドの一覧を表示できる．
Iteration 1では，`relative_error`に`exact::BigFloat`のメソッドを加える．
Iteration 0の`exact::Rational{BigInt}`のメソッドはそのまま残り，参照解の型によって使い分けられる．

## 関数を限定して取り込むusing

`using ..ErrorFreeTransforms: two_sum`は，親モジュールの中にある`ErrorFreeTransforms`から，`two_sum`だけを取り込む．
コロンの後ろに名前を並べると，取り込む名前を限定できる．
どの関数をどのモジュールから使うかがコードから読み取れるので，依存図と照らし合わせやすい．

## テストのグループを選んで実行する

`Pkg.test`の`test_args`に渡した文字列は，`test/runtests.jl`の`ARGS`になる．
このコースの`runtests.jl`では，`"unit"`を渡すと単体テストだけを実行する．

```julia
julia> using Pkg

julia> Pkg.test(test_args = ["unit"])
```

単体テストは結合テストより先に失敗の場所を絞り込めるので，実装の途中ではこちらを使う．
