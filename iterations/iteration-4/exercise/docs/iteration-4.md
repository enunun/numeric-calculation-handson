# Iteration 4の手順：最小二乗法と直交変換

このIterationでは，最小二乗問題min‖Ax − b‖₂を，ハウスホルダー変換によるQR分解で解く関数を作る．
比較のため正規方程式でも解き，条件数が2乗されることを確かめる．
テストには，答えから問題を作る製造解を使う．
最初に，前進代入と後退代入を新しいモジュールへ移すリファクタリングをする．
作業はすべて`iterations/iteration-4/exercise/`で行う．

## 4-1 準備

1. 演習のパッケージを有効にしてREPLを起動し，Pkgモードで`test`を実行する．Iteration 3の模範解答のテストがすべて通る．

   ```text
   Test Summary:  | Pass  Total   Time
   StableNumerics | 1242   1242  20.3s
        Testing StableNumerics tests passed
   ```

2. リポジトリのルートで，`mise run design iterations/iteration-4/exercise`を実行し，設計文書の検査が通ることを確かめる．

## 4-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-4.md)と[理論のノート](../../../../docs/theory/iteration-4.md)を読み，REPLで次の課題を解く．

1. 3 × 2の行列Aを作り，`A'`，`A' * A`，`size(A)`を求める．
2. `v = [1.0, 2.0]`，`w = [3.0, 4.0, 5.0]`について，外積`w * v'`を求める．
3. `x = [3.0, 4.0]`を(−5, 0)に写すハウスホルダー変換H = I − 2vvᵀを作り，`H * x`を確かめる．
4. `t = range(0, 1; length = 50)`，`V = [ti^j for ti in t, j in 0:9]`について，`cond(V)`と`cond(V' * V)`を求め，2乗の関係を確かめる．
5. 2 × 2のアダマール行列`[1 1; 1 -1]`から4 × 4のアダマール行列を作り，`H' * H`を求める．
6. パッケージのディレクトリでREPLを起動し，`include("test/helpers.jl")`と`include("test/unit/linear_solve_tests.jl")`で，LU分解のテストだけを実行する．

## 4-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 列フルランクの縦長行列Aについて，最小二乗問題min‖Ax − b‖₂を解く．
- ハウスホルダー変換によるQR分解で解く．
- 比較のため，正規方程式AᵀAx = Aᵀbでも解ける．
- 多項式の当てはめ(多項式の係数を最小二乗で求める)ができる．
- 行数が列数より少なければ`ArgumentError`を投げる．列フルランクでなければ`SingularException`を投げる．
- 前進代入と後退代入を，LU分解とQR分解で共有できるモジュールに移す．

### 使用例

```julia
julia> t = range(0, 1; length = 50); V = [ti^j for ti in t, j in 0:9]; y = V * ones(10);

julia> maximum(abs, lstsq_qr(V, y) .- 1), maximum(abs, lstsq_normal(V, y) .- 1)
(2.912069474447776e-10, 3.0555489688333104e-5)

julia> polyfit([0.0, 1.0, 2.0, 3.0], [1.0, 3.0, 5.0, 7.0], 1)
2-element Vector{Float64}:
 1.0000000000000004
 1.9999999999999996
```

### 作るもの

- `Triangular`(新規)：`LinearSolve.solve`の前進代入と後退代入を取り出す．
  - `forward_substitution(L::AbstractMatrix{T}, b::AbstractVector{T}; unit_diagonal::Bool = false) where {T<:AbstractFloat}`：対角より上の要素は読まない．`unit_diagonal = true`なら対角を1とみなす．
  - `back_substitution(U::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`：対角より下の要素は読まない．
- `LinearSolve`：`solve`が`Triangular`を使う．
- `LeastSquares`(新規)
  - `struct QRFactorization{T<:AbstractFloat}`：ハウスホルダーベクトルを並べた行列`V`(m × n)と上三角行列`R`(n × n)を持つ．
  - `householder_qr(A::AbstractMatrix{T}) where {T<:AbstractFloat}`
  - `q_factor(F::QRFactorization{T}) where {T<:AbstractFloat}`：Qの最初のn列(m × n)を返す．
  - `lstsq_qr(A::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`
  - `lstsq_normal(A::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`：`LinearSolve`のLU分解で正規方程式を解く．
  - `polyfit(t::AbstractVector{T}, y::AbstractVector{T}, degree::Integer) where {T<:AbstractFloat}`：係数(c₀, …, c_degree)を返す．

### 考えること

- リファクタリングの前後で，既存のテストはどうなるべきか．`Triangular`の新しいテストはどこに置くか．
- 三角行列の連立1次方程式の誤差界は何か．成分ごとの後退誤差を有理数で測れるか．
- 最小二乗解の参照解をどう用意するか．答えから問題を作るとき，丸めの影響をどう避けるか．
- QR分解の誤差界の定数が示されていないとき，許容誤差をどう決め，何を記録するか．
- 参照解を使わずに確かめられる性質(最適性条件，直交性，再構成)はあるか．
- ハウスホルダー変換の符号の選び方を誤ったとき，どんな行列で誤差が大きくなるか．乱数の行列で見つかるか．

## 4-4 設計文書

- `design/modules.md`：`Triangular`と`LeastSquares`を加える．`LinearSolve`と`LeastSquares`は，どのモジュールのどの関数を使うか．
- `design/error-spec.md`：
  - 表の前で，成分ごとの後退誤差ω_c，2ノルムの条件数κ₂，ρ = ‖r‖₂/(‖A‖₂‖x‖₂)を定義する．
  - `forward_substitution`，`back_substitution`，`householder_qr`，`q_factor`，`lstsq_qr`，`lstsq_normal`，`polyfit`の行を加える．`QRFactorization`は型なので表に入れない．
  - 表の下に，QR分解と正規方程式の誤差界の導き方と，定数のわからない誤差界の扱いを書く．
- `design/adr/0005-householder-qr.md`(新規)：最小二乗問題をハウスホルダー変換によるQR分解で解く理由を，正規方程式，グラム・シュミットの直交化，特異値分解と比べて書く．

書いたら`mise run design iterations/iteration-4/exercise`で検査する．

## 4-5 テストファーストの実装

### リファクタリング：Triangularを作る

1. `test/unit/triangular_tests.jl`を作り，前進代入と後退代入の項目を書く．`test/runtests.jl`に登録して実行し，`Triangular`がないことで失敗するのを確かめる．
2. `src/Triangular.jl`を作り，前進代入と後退代入を実装する．
3. `LinearSolve.solve`を，`Triangular`の関数を使うように書き換える．LU分解の結果`F.LU`をそのまま渡せるように，それぞれの関数が読む要素(対角より下，対角より上)を決めておく．
4. `LinearSolve`のテストが変わらずに通ることを確かめる．

### テストデータと参照解

- 有理数で正規方程式を解く厳密な最小二乗解と，2ノルムの相対誤差を求める関数を`test/helpers.jl`に置く．
- 製造解の関数を`test/helpers.jl`に置く．理論のノートの8節のアダマール行列とパスカル行列を使うと，すべての値が小さな整数になる．
- `matrix_with_condition`を縦長の行列も作れるように広げる．

### LeastSquares

- `householder_qr`の各段では，`x = R[k:m, k]`のノルムと符号から`α`を決め，`v = x - αe₁`を正規化する．列が0なら変換は要らない．
- `R[k:m, k:n] .-= 2 .* v .* (v' * R[k:m, k:n])`で，ハウスホルダー変換を残りの部分に作用させる．
- `lstsq_qr`ではQを行列として作らず，ハウスホルダーベクトルを順にbに作用させてQᵀbを求める．
- `polyfit`はヴァンデルモンド行列を内包表記で作り，`lstsq_qr`で解く．
- 1つのモジュールを実装している間は，REPLで`test/helpers.jl`とそのモジュールのテストファイルだけを`include`して実行すると速い．

### よくある間違い

- `α`の符号を`sign(x₁)`と同じにする．列がe₁とほぼ平行な場合，桁落ちが起きる．
- ハウスホルダー変換の係数2を忘れる．Hが直交行列でなくなる．
- 製造解で，`A * x + r`の計算で丸めが起きる値を使う．xが厳密な最小二乗解でなくなる．
- 正規方程式の許容誤差に，QR分解と同じκ₂の式を使う．

## 4-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．
2. リファクタリングの前後で，`LinearSolve`のテストの件数と結果はどうだったか．
3. `householder_qr`の`α`の符号を逆にすると，乱数の行列のテストは失敗するか．失敗しないなら，どんな入力を加えれば見つかるか(確かめたら元に戻す)．
4. 製造解と，有理数で求めた参照解は，それぞれどんな利点と欠点を持つか．
5. 結合テストで，正規方程式の誤差がQR分解の許容誤差を超えることを確かめる意味は何か．
6. 設計文書と実装を見比べ，食い違うところを直す．`mise run design iterations/iteration-4/exercise`が通るようにする．

## 4-7 発展課題

重み付き最小二乗法min Σᵢ wᵢ(aᵢᵀx − bᵢ)²(wᵢ > 0)を解く関数を作る．
行ごとに√wᵢを掛けた問題を`lstsq_qr`で解けばよい．
次の性質を確かめる．

- すべての重みが4なら，重みなしの結果と厳密に一致する(√4 = 2による拡大縮小は丸め誤差を生まない)．
- すべての重みが等しい3なら，重みなしの結果と許容誤差の範囲で一致する．

テストリスト，設計文書，テストファーストの実装の順に進める．
