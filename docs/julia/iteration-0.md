# Iteration 0：Juliaの基本，パッケージ，テスト

Iteration 0で使うJuliaの文法と機能をまとめる．
例はREPLで試せる．`julia>`の後ろが入力で，その下が出力である．

## REPLとパッケージ

### REPLの起動

パッケージのディレクトリで次のように起動すると，そのパッケージが有効になる．

```sh
julia --project=.
```

`--project=.`は「現在のディレクトリの`Project.toml`を使う」という意味である．
REPLを起動したら，`using StableNumerics`でパッケージを読み込める．

REPLには入力のモードがある．

| 入力 | モード | 用途 |
| --- | --- | --- |
| (そのまま) | `julia>` | Juliaの式を評価する |
| `]` | `pkg>` | パッケージの操作(`test`，`status`など) |
| `?` | `help?>` | 関数の説明(docstring)を表示する |
| `;` | `shell>` | シェルのコマンドを実行する |

`pkg>`などのモードからは，行の先頭でBackspaceを押すと`julia>`に戻る．

### テストの実行

`pkg>`モードで`test`と入力すると，パッケージの`test/runtests.jl`が新しいプロセスで実行される．

```text
pkg> test
```

REPLを使わずに，シェルから同じことができる．

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

### `Project.toml`

`Project.toml`はパッケージの名前，UUID，依存を書くファイルである．
`[extras]`と`[targets]`には，テストのときだけ使うパッケージ(ここでは標準ライブラリの`Test`)を書く．

```toml
name = "StableNumerics"
uuid = "1924ff7f-4db1-4ad7-bcac-7464768bc610"
version = "0.1.0"

[extras]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Test"]
```

## モジュール

`module 名前 ... end`で名前空間を作る．
`export`した名前は，`using`したときにモジュール名を付けずに使える．

```julia
# src/Summation.jl
module Summation

export naive_sum

function naive_sum(xs)
    # ...
end

end
```

`include("ファイル名")`は，ファイルの中身をその場所に書いたのと同じ効果を持つ．
パッケージの本体`src/StableNumerics.jl`では，各モジュールのファイルを`include`し，`using`で取り込んでから，公開する名前を`export`する．

```julia
module StableNumerics

include("Summation.jl")

using .Summation

export naive_sum

end
```

`using .Summation`の`.`は「このモジュールの中にあるSummation」を表す．
Iteration 1では，あるモジュールから隣のモジュールを`using ..ErrorFreeTransforms`(親の中にあるモジュール)の形で使う．

パッケージの外からは，`StableNumerics.Summation`のように`.`でつないで中のモジュールを指せる．
単体テストでは`using StableNumerics.Summation`と書き，テストするモジュールを明示する．

## 数値の型

```julia
julia> typeof(1.0), typeof(1.0f0), typeof(1)
(Float64, Float32, Int64)

julia> Float64 <: AbstractFloat
true

julia> eps(Float32)
1.1920929f-7

julia> zero(Float32)
0.0f0
```

- `1.0`の型は`Float64`(倍精度)，`1.0f0`の型は`Float32`(単精度)，`1`の型は`Int64`である．
- `A <: B`は「型Aは型Bの部分型である」を表す．`Float64`と`Float32`は，抽象型`AbstractFloat`の部分型である．
- `eps(T)`は型Tのマシンイプシロン，`eps(x)`は値xのULP，`nextfloat(x)`はxの次の浮動小数点数，`bitstring(x)`はxのビット列を返す．
- `zero(T)`は型Tの0を返す．総和の初期値の型を，引数の要素の型とそろえるのに使う．

### 有理数

`a // b`は有理数を作る．`Rational{BigInt}(x)`は浮動小数点数xを，それが表す有理数に**厳密に**変換する．
`BigInt`は桁数に制限のない整数なので，足し算を何回しても丸め誤差は生じない．

```julia
julia> 1 // 3 + 1 // 6
1//2

julia> Rational{BigInt}(0.75)
3//4

julia> Rational{BigInt}(0.1)
3602879701896397//36028797018963968
```

## 関数

1行で書ける関数は`名前(引数) = 式`と書ける．
長い関数は`function ... end`で書き，`return`で値を返す．

```julia
julia> double(x) = 2x
double (generic function with 1 method)

julia> double(1.5)
3.0
```

`2x`は`2 * x`の省略形である(数値の直後に変数名を書くと掛け算になる)．

### 型注釈と型パラメータ

引数に`::型`を付けると，その型の値だけを受け付ける．
`where {T<:AbstractFloat}`は，「Tは`AbstractFloat`の部分型のどれか」という型パラメータを導入する．
次の関数は，ベクトルの要素とfactorが同じ型の浮動小数点数のときだけ呼べる．

```julia
julia> function scaled_sum(xs::AbstractVector{T}, factor::T) where {T<:AbstractFloat}
           s = zero(T)
           for x in xs
               s += factor * x
           end
           return s
       end
scaled_sum (generic function with 1 method)

julia> scaled_sum([1.0, 2.0, 3.0], 0.5)
3.0

julia> scaled_sum([1.0f0, 2.0f0], 0.5f0)
1.5f0

julia> scaled_sum([1.0, 2.0], 0.5f0)
ERROR: MethodError: no method matching scaled_sum(::Vector{Float64}, ::Float32)
The function `scaled_sum` exists, but no method is defined for this combination of argument types.

Closest candidates are:
  scaled_sum(::AbstractVector{T}, !Matched::T) where T<:AbstractFloat
```

`Float64`と`Float32`を混ぜると，呼べるメソッドがないというエラーになる．
`unit_roundoff(::Type{T})`のように`::Type{T}`と書くと，値ではなく型そのもの(`Float64`など)を引数に取れる．

### タプルと分割代入

`(a, b)`はタプルである．関数から複数の値を返すのに使う．
`s, e = タプル`と書くと，要素を別々の変数に取り出せる．

```julia
julia> pair = (1.0, 2.0)
(1.0, 2.0)

julia> a, b = pair
(1.0, 2.0)
```

### 条件式と短絡評価

`条件 ? 式1 : 式2`は，条件が真なら式1，偽なら式2の値になる(三項演算子)．
`条件 && 式`は条件が真のときだけ式を評価し，`条件 || 式`は条件が偽のときだけ式を評価する(短絡評価)．
`iszero(total) && return T(Inf)`のように，「この場合はすぐに返す」という書き方に使う．

```julia
julia> x = 0.0
0.0

julia> iszero(x) ? "ゼロ" : "ゼロ以外"
"ゼロ"

julia> iszero(x) && "ゼロなので評価される"
"ゼロなので評価される"

julia> x > 1 || "1以下なので評価される"
"1以下なので評価される"
```

### 例外

`throw(ArgumentError("説明"))`で，引数が不正であることを知らせる例外を投げる．
`条件 || throw(...)`は「条件が偽なら例外を投げる」という書き方である．

```julia
julia> throw(ArgumentError("nが大きすぎる"))
ERROR: ArgumentError: nが大きすぎる
```

### docstring

関数の直前に`"""`で囲んだ文字列を書くと，その関数の説明になる．
REPLの`help?>`モードで関数名を入力すると表示される．

```julia
"""
    naive_sum(xs)

先頭から順に足した総和を返す．
"""
function naive_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}
    # ...
end
```

## ベクトルを作る

```julia
julia> [k^2 for k in 1:5]
5-element Vector{Int64}:
  1
  4
  9
 16
 25

julia> map(abs, [-1.0, 2.0, -3.0])
3-element Vector{Float64}:
 1.0
 2.0
 3.0

julia> fill(0.1, 3)
3-element Vector{Float64}:
 0.1
 0.1
 0.1

julia> vcat([1.0, 2.0], [3.0])
3-element Vector{Float64}:
 1.0
 2.0
 3.0
```

- `[式 for 変数 in 範囲]`は内包表記で，範囲の各値について式を計算したベクトルを作る．`1:5`は1から5までの範囲である．
- `map(f, xs)`は，xsの各要素にfを適用したベクトルを返す．
- `fill(x, n)`はxをn個並べたベクトル，`vcat(a, b)`はベクトルを縦につないだものを返す．
- `Float64[]`は空の`Float64`のベクトルである．

`名前 => 値`はペア(`Pair`)を作る．テストデータに名前を付けて並べるのに使う．

```julia
julia> "0.1を3個" => fill(0.1, 3)
"0.1を3個" => [0.1, 0.1, 0.1]
```

`for (name, xs) in ペアのベクトル`と書くと，各ペアの名前と値を取り出しながら繰り返せる．

## 文字列の補間

文字列の中の`$(式)`は式の値に置き換わる．

```julia
julia> n = 5; "n = $(n)です"
"n = 5です"
```

`$n`と括弧を省くこともできるが，直後に日本語を続けると日本語まで変数名とみなされる．日本語の文の中では`$(n)`と書く．

## テスト

標準ライブラリ`Test`のマクロを使う．

```julia
julia> using Test

julia> @test 1.0 + 2.0 == 3.0
Test Passed

julia> @test 0.1 + 0.2 == 0.3
Test Failed at none:1
  Expression: 0.1 + 0.2 == 0.3
   Evaluated: 0.30000000000000004 == 0.3

ERROR: There was an error during testing

julia> @test 0.1 + 0.2 ≈ 0.3 rtol = 4eps()
Test Passed

julia> @test_throws ArgumentError throw(ArgumentError("x"))
Test Passed
      Thrown: ArgumentError
```

- `@test 式`は，式が`true`なら合格，`false`なら不合格(Fail)，例外が起きたらエラー(Error)になる．
- `@test a ≈ b rtol = r`は`isapprox(a, b; rtol = r)`，つまり|a − b| ≤ r·max(|a|, |b|)を検査する．`atol = t`を付けると絶対誤差の許容値も指定できる．`≈`は`\approx`と入力してTabキーを押すと入力できる．
- `@test_throws 例外の型 式`は，式がその型の例外を投げることを検査する．
- `@testset "名前" begin ... end`は，テストをまとめて名前を付ける．最後に合格・不合格の数が表示される．`@testset`は入れ子にできる．

```julia
julia> @testset "例" begin
           @test 1 + 1 == 2
           @test sqrt(4.0) == 2.0
       end
Test Summary: | Pass  Total  Time
例            |    2      2  0.0s
```

### `test/runtests.jl`の`ARGS`

`Pkg.test(test_args = ["unit"])`のように渡した引数は，`test/runtests.jl`の中で`ARGS`という文字列のベクトルとして受け取れる．
このコースの`runtests.jl`は，`ARGS`が空ならすべてのグループを，そうでなければ指定されたグループだけを実行する．
