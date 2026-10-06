# Iteration 3：構造体，行列，LinearAlgebra

Iteration 3で初めて使うJuliaの文法と機能をまとめる．

## 構造体

`struct 名前 ... end`で，いくつかの値をまとめた型(構造体)を定義する．
値は`型名(値1, 値2)`で作り，`.フィールド名`で取り出す．

```julia
julia> struct Interval
           lo::Float64
           hi::Float64
       end

julia> r = Interval(1.0, 2.0)
Interval(1.0, 2.0)

julia> r.lo, r.hi
(1.0, 2.0)
```

`struct`で定義した構造体は不変で，作った後にフィールドを付け替えられない．
ただし，フィールドが配列なら，配列の要素は書き換えられる．

### パラメータ型

`struct 名前{T<:AbstractFloat}`のように，型パラメータを持つ構造体を定義できる．
フィールドの型を`T`にすると，作るときの値の型からTが決まる．

```julia
julia> struct Box{T<:AbstractFloat}
           value::T
       end

julia> Box(1.0f0)
Box{Float32}(1.0f0)
```

`LUFactorization{T}`は，`Float64`の行列から作ると`LUFactorization{Float64}`になる．
`solve(F::LUFactorization{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`は，分解とbの要素の型がそろっているときだけ呼べる．

## キーワード引数

引数の並びの`;`より後ろに書いた引数は，キーワード引数である．呼ぶときに名前を付けて渡し，省略すると既定値になる．

```julia
julia> scale(x; factor = 2.0) = factor * x
scale (generic function with 1 method)

julia> scale(3.0), scale(3.0; factor = 10.0)
(6.0, 30.0)
```

`lu_factorize(A; pivot = false)`のように，振る舞いを切り替える引数に使う．

## 行列

`[1.0 2.0; 3.0 4.0]`のように，要素を空白で，行を`;`で区切って行列を作る．
内包表記`[f(i, j) for i in 1:n, j in 1:n]`でも作れる．

```julia
julia> M = [1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 10.0]
3×3 Matrix{Float64}:
 1.0  2.0   3.0
 4.0  5.0   6.0
 7.0  8.0  10.0

julia> M[2, 3], M[2, :], M[:, 1]
(6.0, [4.0, 5.0, 6.0], [1.0, 4.0, 7.0])

julia> M[2:3, 2:3]
2×2 Matrix{Float64}:
 5.0   6.0
 8.0  10.0
```

- `M[i, j]`はi行j列の要素，`M[i, :]`はi行目，`M[:, j]`はj列目である．`:`は「その次元のすべて」を表す．
- `M[2:3, 2:3]`のように範囲で取り出すと，部分行列のコピーができる．
- `size(M)`は行数と列数の組，`size(M, 1)`は行数を返す．

添字にベクトルを使うと，行の入れ替えが1行で書ける．

```julia
julia> M[[1, 2], :] = M[[2, 1], :]; M
3×3 Matrix{Float64}:
 4.0  5.0   6.0
 1.0  2.0   3.0
 7.0  8.0  10.0
```

## コピーと破壊的な関数

`w = v`は同じ配列に別の名前を付けるだけで，配列をコピーしない．
コピーするには`copy(v)`を使う．行列の要素の型をそろえてコピーするには，`Matrix{T}(A)`も使える．

```julia
julia> v = [1.0, 2.0, 3.0]; w = v; w[1] = 100.0; v
3-element Vector{Float64}:
 100.0
   2.0
   3.0

julia> v = [1.0, 2.0, 3.0]; w = copy(v); w[1] = 100.0; v
3-element Vector{Float64}:
 1.0
 2.0
 3.0
```

引数の配列を書き換える関数には，名前の最後に`!`を付ける習慣がある．

```julia
julia> function double!(v)
           for i in eachindex(v)
               v[i] *= 2
           end
           return v
       end
double! (generic function with 1 method)

julia> double!(v); v
3-element Vector{Float64}:
 2.0
 4.0
 6.0
```

`lu_factorize`は，引数の行列をコピーしてから分解するので，Aを書き換えない．名前に`!`は付けない．

## LinearAlgebra

標準ライブラリ`LinearAlgebra`は，行列とベクトルの関数を提供する．

```julia
julia> norm([3.0, -4.0]), norm([3.0, -4.0], Inf), opnorm([1.0 -2.0; 3.0 4.0], Inf)
(5.0, 4.0, 7.0)

julia> tril([1.0 2.0; 3.0 4.0], -1), triu([1.0 2.0; 3.0 4.0])
([0.0 0.0; 3.0 0.0], [1.0 2.0; 0.0 4.0])
```

| 関数 | 意味 |
| --- | --- |
| `norm(x)`，`norm(x, Inf)` | ベクトルの2ノルム，∞ノルム |
| `opnorm(A, Inf)` | 行列の∞ノルム(作用素ノルム) |
| `cond(A, Inf)` | 行列の∞ノルムの条件数(浮動小数点数で計算した近似値) |
| `tril(A, -1)`，`triu(A)` | 対角より下の部分，対角を含む上の部分 |
| `I` | 大きさを自動で合わせる単位行列 |
| `Diagonal(σ)` | ベクトルσを対角に並べた対角行列 |
| `qr(A).Q` | QR分解の直交行列Q(`Matrix(...)`で普通の行列にする) |
| `A \ b` | Ax = bの解．有理数の行列なら厳密に解く |
| `inv(A)` | 逆行列 |

`using LinearAlgebra: SingularException`のように書くと，`LinearAlgebra`から名前を1つだけ取り込める．
`SingularException(k)`は，k番目のピボットが0で行列が特異であることを表す例外である．
引数の大きさが合わないときは，Juliaの標準の例外`DimensionMismatch`を投げる．

### パッケージの依存に加える

`LinearAlgebra`はテストだけでなくパッケージ本体(`SingularException`)でも使うので，パッケージの依存に加える．
パッケージを有効にしたREPLのPkgモードで`add`を実行する．

```text
pkg> add LinearAlgebra
   Resolving package versions...
      Compat entries added for LinearAlgebra
    Updating `…/Project.toml`
  [37e2e46d] + LinearAlgebra v1.12.0
```

`Project.toml`に`[deps]`と，対応できる版を表す`[compat]`の項目が加わる．

```toml
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[compat]
LinearAlgebra = "1.12.0"
julia = "1.12"
```

`[deps]`のパッケージは，テストでも`using`できる．

## argmaxと最大値

`argmax(v)`は，最大の要素の位置を返す．絶対値の最大の位置は`argmax(abs.(v))`で求める．

```julia
julia> argmax([3.0, -7.0, 5.0]), argmax(abs.([3.0, -7.0, 5.0]))
(3, 2)
```

`maximum(abs, v)`は絶対値の最大値，`sum(abs, A; dims = 2)`は行ごとの絶対値の和(1列の行列)を返す．
