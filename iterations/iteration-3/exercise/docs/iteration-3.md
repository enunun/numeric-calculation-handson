# Iteration 3の手順：連立1次方程式と後退安定性

このIterationでは，LU分解で連立1次方程式Ax = bを解く関数を作る．
ピボット選択が解の精度をどう変えるかを，増大因子と後退誤差で確かめる．
条件の悪い行列では前進誤差が大きくなることを理論で説明し，テストの許容誤差を後退誤差と条件数から決める．
作業はすべて`iterations/iteration-3/exercise/`で行う．

## 3-1 準備

1. 演習のパッケージを有効にしてREPLを起動し，Pkgモードで`test`を実行する．Iteration 2の模範解答のテストがすべて通る．

   ```text
   Test Summary:  | Pass  Total  Time
   StableNumerics |  868    868  5.0s
        Testing StableNumerics tests passed
   ```

2. リポジトリのルートで，`mise run design iterations/iteration-3/exercise`を実行し，設計文書の検査が通ることを確かめる．

## 3-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-3.md)と[理論のノート](../../../../docs/theory/iteration-3.md)を読み，REPLで次の課題を解く．
`LinearAlgebra`の関数は，REPLで`using LinearAlgebra`をしてから使う．

1. 2つのフィールド`lo`，`hi`を持つ構造体を定義し，値を作ってフィールドを取り出す．
2. `[2.0 1.0; 4.0 3.0]`のLU分解を手で計算する．ピボット選択なしと，部分ピボット選択の両方で，LとUを求める．
3. 3 × 3の行列を作り，1行目と3行目を添字のベクトルで入れ替える．
4. `A = [1e-20 1.0; 1.0 1.0]`，`b = [1.0, 2.0]`について，`A * [1.0, 1.0] - b`を計算する．次に，`Rational{BigInt}.(A) * Rational{BigInt}.([1.0, 1.0]) - Rational{BigInt}.(b)`を計算する．結果が違う理由を説明する．
5. 10 × 10のヒルベルト行列Hを内包表記で作り，`cond(H, Inf)`を求める．`b = H * ones(10)`として`H \ b`を計算し，`ones(10)`と比べる．
6. 行列`[1.0 2.0; 3.0 4.0]`の∞ノルムを，定義(行ごとの絶対値の和の最大値)と`opnorm`の両方で求める．

## 3-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 正方行列AのLU分解を求める．既定では部分ピボット選択をし，比較のためにピボット選択なしも選べる．
- LU分解を使って連立1次方程式Ax = bを解く．
- 計算した解の(ノルムによる)後退誤差を求める．
- 分解の増大因子を求める．
- ピボットが0になったら`SingularException`を投げる．正方行列でなければ`DimensionMismatch`を投げる．

### 使用例

```julia
julia> A = [1e-20 1.0; 1.0 1.0]; b = [1.0, 2.0];

julia> solve(lu_factorize(A; pivot = false), b), solve(lu_factorize(A), b)
([0.0, 1.0], [1.0, 1.0])

julia> backward_error(A, [0.0, 1.0], b), backward_error(A, [1.0, 1.0], b)
(0.25, 2.5e-21)
```

### 作るもの

- `LinearSolve`(新規)
  - `struct LUFactorization{T<:AbstractFloat}`：`LU::Matrix{T}`(Lの狭義下三角とUを1つの行列に格納)と`perm::Vector{Int}`(PAのi行目がAの`perm[i]`行目)を持つ．
  - `lu_factorize(A::AbstractMatrix{T}; pivot::Bool = true) where {T<:AbstractFloat}`
  - `solve(F::LUFactorization{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`
  - `backward_error(A::AbstractMatrix{T}, x::AbstractVector{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`：‖b − Ax‖∞/(‖A‖∞‖x‖∞ + ‖b‖∞)を返す．
  - `growth_factor(F::LUFactorization{T}, A::AbstractMatrix{T}) where {T<:AbstractFloat}`：maxᵢⱼ|uᵢⱼ|/maxᵢⱼ|aᵢⱼ|を返す．

### 考えること

- 分解の正しさを，解を求めずに確かめる方法はあるか(PA ≈ LU)．どんな不等式で比べるか．
- 解の精度は，前進誤差と後退誤差のどちらで検査するか．条件数が10¹³を超える行列でも成り立つ許容誤差はどう決めるか．
- 厳密解，厳密な条件数，厳密な残差を求める方法はあるか．
- テスト行列には，どんな行列を含めるべきか．条件数，ピボットの大きさ，増大因子の大きさを考える．
- `backward_error`の残差を浮動小数点数で計算すると，何が困るか．

## 3-4 設計文書

- `design/modules.md`：`LinearSolve`はほかのどのモジュールを使うか．`LinearAlgebra`のような標準ライブラリへの依存は図に描かず，説明に書く．
- `design/error-spec.md`：
  - 表の前で，ノルム，条件数κ(A)，後退誤差η，ω = ‖|L̂||Û|‖∞/‖A‖∞，増大因子ρを定義する．
  - `lu_factorize`，`solve`，`backward_error`，`growth_factor`の行を加える．`LUFactorization`は型なので表に入れない．
  - `solve`の誤差界は，理論のノートの5節から7節を参考に，後退誤差と前進誤差の両方を書く．
  - 表の下に，誤差界の導き方と，残差を厳密に計算する理由を書く．
- `design/adr/0004-partial-pivoting.md`(新規)：部分ピボット選択を既定にした理由と，受け入れ基準を後退誤差にした理由を書く．

書いたら`mise run design iterations/iteration-3/exercise`で検査する．

## 3-5 テストファーストの実装

### LinearAlgebraを依存に加える

`LinearSolve`は，特異な行列で`LinearAlgebra`の`SingularException`を投げる．
パッケージを有効にしたREPLで，Pkgモードの`add`で`LinearAlgebra`を依存に加える．
`Project.toml`に何が加わったかを確かめる．

### テスト行列と参照解

`test/helpers.jl`に次を置く．

- 有理数で計算する参照解：行列の∞ノルム，厳密解，厳密な条件数，前進誤差，誤差界γ₃ₙω．
- テスト行列：条件数を指定した乱数の行列(理論のノートの9節)，ヒルベルト行列，Wilkinsonの行列．

有理数の計算は遅いので，乱数の行列の大きさは12 × 12までにする．

### LinearSolve

- `lu_factorize`は，引数の行列をコピーしてから分解する．`perm`は1:nから始め，行を入れ替えるときは`perm`の要素も同じように入れ替える．
- ピボットの選択には`argmax`と`abs.`を使う．
- `solve`は，`b[F.perm]`から前進代入と後退代入をする．Lの対角は1である．
- `backward_error`は，`Rational{BigInt}.`で行列とベクトルを有理数にしてから残差とノルムを計算する．
- `growth_factor`のUの要素は，`F.LU`の対角とその右上の要素である．

### よくある間違い

- ピボットの選択で`abs`を忘れる．負の大きな要素を選ばないので，乗数の絶対値が1を超える．
- `perm`を入れ替えずに`LU`の行だけを入れ替える．
- 後退誤差の上界にγ₃ₙ·ρを使う．ωはn²ρまで大きくなりうるので，n²の係数が要る(またはωを直接計算する)．
- ヒルベルト行列の前進誤差を`ones(n)`と比べる．bを計算したときの丸めで，厳密解は`ones(n)`からずれている．

## 3-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．
2. `lu_factorize`の既定を`pivot = false`にすると，どのテストが失敗するか．後退誤差の誤差界γ₃ₙωのテストは失敗するか．理由を説明する(確かめたら元に戻す)．
3. `backward_error`の残差を浮動小数点数で計算するように変えると，どのテストが失敗するか．
4. ヒルベルト行列で，前進誤差を固定の許容誤差(例えばγ₃ₙ)で検査すると何が起きるか．その許容誤差を緩めて通すのはなぜいけないか．
5. 単体テストと結合テストは，それぞれ何を確かめているか．
6. 設計文書と実装を見比べ，食い違うところを直す．`mise run design iterations/iteration-3/exercise`が通るようにする．

## 3-7 発展課題

反復改良(iterative refinement)を実装する．
解x̂の残差r = b − Ax̂を正確に計算し，同じLU分解でAd = rを解いて，x̂ ← x̂ + dと更新する．
残差は，`two_prod`と`two_sum`で内積を2倍の精度と同程度に計算する方法(Ogita–Rump–OishiのDot2)で求める．
ヒルベルト行列で，更新を3回繰り返したときの前進誤差を，有理数で求めた厳密解と比べる．

テストリスト，設計文書，テストファーストの実装の順に進める．
