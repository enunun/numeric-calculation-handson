# Iteration 4：転置，外積，部分行列の更新

Iteration 4で初めて使うJuliaの文法と機能をまとめる．

## 転置

`transpose(A)`は行列の転置を返す．実数の行列では，`A'`(随伴，複素共役の転置)も同じ結果になる．

```julia
julia> A = [1.0 2.0; 3.0 4.0; 5.0 6.0]
3×2 Matrix{Float64}:
 1.0  2.0
 3.0  4.0
 5.0  6.0

julia> transpose(A), A'
([1.0 3.0 5.0; 2.0 4.0 6.0], [1.0 3.0 5.0; 2.0 4.0 6.0])

julia> size(A), size(A, 1)
((3, 2), 3)
```

`A' * b`はAᵀbを，`A' * A`はAᵀAを計算する．

## 行ベクトルと外積

列ベクトルvの転置`v'`は1行の行列(行ベクトル)として振る舞う．
`w * v'`は外積wvᵀ(m × nの行列)，`v' * M`は行ベクトルと行列の積である．

```julia
julia> v = [1.0, 2.0]; w = [3.0, 4.0, 5.0];

julia> w * v'
3×2 Matrix{Float64}:
 3.0   6.0
 4.0   8.0
 5.0  10.0

julia> v' * [1.0 0.0; 0.0 1.0]
1×2 adjoint(::Vector{Float64}) with eltype Float64:
 1.0  2.0
```

## 部分行列の更新

`M[範囲, 範囲] .-= 式`は，部分行列の各要素から，右辺の対応する要素を引く．
右辺の`v .* (v' * M)`は，列ベクトルvと行ベクトルv'Mのブロードキャストによる積で，外積v(vᵀM)になる．
ハウスホルダー変換をM ← M − 2v(vᵀM)の形で作用させるのに使う．

```julia
julia> M = zeros(3, 2); M[2:3, :] .-= 2 .* [1.0, 1.0] .* [1.0 2.0]; M
3×2 Matrix{Float64}:
  0.0   0.0
 -2.0  -4.0
 -2.0  -4.0
```

`.-=`の左辺の部分行列は，元の行列Mの一部として書き換えられる．
一方，右辺の`R[k:m, k]`のような添字での取り出しはコピーを作るので，取り出したベクトルを書き換えても元の行列は変わらない．

## 単位行列の一部

`Matrix{Float64}(I, m, n)`は，m × nの行列で，対角が1，ほかが0のものを作る．
QR分解のQの最初のn列を作るときの出発点に使う．

```julia
julia> using LinearAlgebra

julia> Matrix{Float64}(I, 3, 2)
3×2 Matrix{Float64}:
 1.0  0.0
 0.0  1.0
 0.0  0.0
```

## 特定のテストファイルだけを実行する

パッケージのディレクトリでREPLを起動し，テストファイルを`include`すると，そのファイルのテストだけを実行できる．
テストファイルが使う補助関数(`test/helpers.jl`)を先に`include`する．

```julia
julia> using Test, StableNumerics

julia> include("test/helpers.jl");

julia> include("test/unit/triangular_tests.jl");
Test Summary: | Pass  Total  Time
Triangular    |  108    108  1.9s
```

`Pkg.test`は新しいプロセスを起動してすべてのテストを実行するので時間がかかる．
1つのモジュールを実装している間は，この方法で関係するテストだけを繰り返し実行すると速い．
ソースを書き換えた後は，REPLを起動し直すか，Revise.jlのようなツールを使わないと変更が反映されない．
最後は必ず`Pkg.test`ですべてのテストを実行する．
