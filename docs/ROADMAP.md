# ロードマップ

このハンズオンでは，Juliaのパッケージ`StableNumerics`を6回のIterationで育てる．
`StableNumerics`は「素朴に書くと壊れる」数値計算を，誤差の理論に基づいて安定に計算するライブラリである．
各Iterationでは，壊れ方を理論で説明し，許容誤差を理論から導き，その主張をテストで保証する．

## 完成したライブラリの使用例

```julia
julia> using StableNumerics

julia> xs = [1e16, 1.0, -1e16];

julia> naive_sum(xs), compensated_sum(xs)
(0.0, 1.0)

julia> quadratic_roots(1.0, 1e8, 1.0)
(-1.0e8, -1.0e-8)

julia> data = [1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16];

julia> textbook_variance(data), variance(data)
(-170.66666666666666, 30.0)

julia> H = [1 / (i + j - 1) for i in 1:10, j in 1:10]; b = H * ones(10);

julia> x = solve(lu_factorize(H), b);

julia> backward_error(H, x, b)   # 後退誤差は単位丸め程度
7.578404543311813e-17

julia> t = range(0, 1; length = 50); V = [ti^j for ti in t, j in 0:9]; y = V * ones(10);

julia> maximum(abs, lstsq_qr(V, y) .- 1), maximum(abs, lstsq_normal(V, y) .- 1)
(2.912133867383204e-10, 3.0555489688333104e-5)

julia> exponential(1.0)
2.718281828459045

julia> ulp_error(exponential(1.0), exp(big(1.0)))
0.32553074014505834
```

## Iterationの進め方

どのIterationも，次の順に進める．

1. 要件と使用例を読み，確かめるべき振る舞いをテストリスト(`TESTLIST.md`)に書き出す．
2. `design/`の設計文書(依存図・誤差仕様書・ADR)を更新する．誤差仕様書には，関数ごとに条件数・誤差界・許容誤差の根拠・検証するテストを書く．
3. テストリストの項目を1つずつ，テストファーストでRed → Green → Refactorと進める．
4. 設計文書と実装を見比べ，食い違いを直す(設計レビュー)．

各Iterationの教材は`iterations/iteration-N/`にある．

- `exercise/`：学習者が作業するパッケージ．Iteration N(N ≥ 1)の`exercise/`は，Iteration N-1の`solution/`と同じコードから始まる．
- `solution/`：完成したパッケージと模範解答．

## テストの分け方

| 種類 | 確かめること | 置き場所 |
| --- | --- | --- |
| 単体テスト | 1つのモジュールの関数を，そのモジュールだけで確かめる．厳密解・高精度解との比較，誤差界の検査，性質の検査を含む | `test/unit/<モジュール名>_tests.jl` |
| 結合テスト | `using StableNumerics`で公開されたAPIだけを使い，複数のモジュールを組み合わせた計算の筋書きを確かめる | `test/integration/` |

テストの許容誤差は，誤差仕様書に書いた誤差界から導く．
根拠のない数値(`1e-10`など)を許容誤差に使わない．

## Iteration一覧

| Iteration | 作る機能 | 数値計算の理論 | 品質保証の手法 |
| --- | --- | --- | --- |
| 0 | 総和(素朴・補償付き)，総和の条件数 | IEEE 754，丸め誤差の標準モデル，条件数，前進誤差 | 有理数による厳密な参照解，理論から導く許容誤差，無誤差変換の厳密な検査 |
| 1 | 二次方程式の実根 | 桁落ち，根の条件数，後退誤差，fma | 高精度(BigFloat)の参照解，特殊値の検査，性質(解と係数の関係)の検査 |
| 2 | 平均と分散 | 分散の条件数，Welfordの算法，不安定な算法 | 性質ベーステスト，乱数シードの管理，厳密に成り立つ性質と近似的に成り立つ性質 |
| 3 | LU分解による連立1次方程式 | 行列の条件数，後退安定性，増大因子，前進誤差の上界 | 残差による検査，条件数を指定したテスト行列 |
| 4 | QR分解による最小二乗法 | 直交変換の安定性，正規方程式によるκ²の悪化 | 製造解(答えから問題を作る)，リファクタリングの安全網としてのテスト |
| 5 | 指数関数 | ULP誤差，引数還元，打ち切り誤差と丸め誤差の誤差予算 | ULPによる精度保証，境界値・局所全数・差分テスト |

## Iteration 0：浮動小数点数と総和

### 要件

- 浮動小数点数のベクトルの総和を，素朴な方法(先頭から順に足す)と補償付きの方法で計算できる．
- 2つの浮動小数点数の和を，丸めた和と丸め誤差の組に分解できる．この分解に誤差はない．
- 総和の条件数を計算できる．
- 単位丸めと，誤差解析に使う定数γₙを計算できる．
- 計算結果の相対誤差を，厳密な値(有理数)と比べて求められる．

### 使用例

```julia
julia> naive_sum([1e16, 1.0, -1e16]), compensated_sum([1e16, 1.0, -1e16])
(0.0, 1.0)

julia> two_sum(1e16, 1.0)
(1.0e16, 1.0)

julia> sum_condition_number([1e16, 1.0, -1e16])
2.0e16

julia> unit_roundoff(Float64), gamma(10, Float64)
(1.1102230246251565e-16, 1.1102230246251577e-15)

julia> relative_error(naive_sum(fill(0.1, 10)), 10 * Rational{BigInt}(0.1))
1.6653345369377348e-16
```

### モジュール

- `ErrorBounds`
  - `unit_roundoff(::Type{T}) where {T<:AbstractFloat}`：単位丸めu = eps(T)/2を返す．
  - `gamma(n::Integer, ::Type{T}) where {T<:AbstractFloat}`：γₙ = nu/(1 − nu)を返す．nu ≥ 1なら`ArgumentError`を投げる．
  - `relative_error(computed::AbstractFloat, exact::Rational{BigInt})`：|computed − exact|/|exact|を有理数で厳密に求め，`Float64`で返す．
- `Summation`
  - `two_sum(a::T, b::T) where {T<:AbstractFloat}`：`(s, e)`を返す．s = fl(a + b)で，a + b = s + eが厳密に成り立つ．
  - `naive_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}`
  - `compensated_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}`：`two_sum`で各段の丸め誤差を集めて最後に足す(Ogita–Rump–OishiのSum2)．
  - `sum_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat}`：Σ|xᵢ|/|Σxᵢ|を返す．総和が0なら`Inf`を返す．
- `StableNumerics`：上の関数を公開する．

### 設計文書の更新

- `design/modules.md`：`StableNumerics`と`ErrorBounds`・`Summation`の依存図を初めて描く．
- `design/error-spec.md`：公開する関数ごとに，条件数・誤差界・許容誤差・検証するテストの表を初めて書く．素朴な総和の誤差界はγₙ₋₁·κ，補償付き総和の誤差界はu + γₙ₋₁²·κである．
- `design/adr/0001-compensated-summation.md`：補償付き総和の方式としてSum2を選んだ理由を書く．

### 学ぶこと

- 数値計算の理論：IEEE 754の倍精度と最近接偶数丸め，マシンイプシロンと単位丸め，丸め誤差の標準モデルfl(a ∘ b) = (a ∘ b)(1 + δ)，ULP，絶対誤差と相対誤差．総和の条件数と，素朴な総和の前進誤差の上界．無誤差変換(TwoSum)．
- 品質保証：`==`で浮動小数点数を比べてはいけない理由と`≈`の既定の許容誤差，有理数演算による厳密な参照解，許容誤差を誤差界から導く方法，無誤差変換は「誤差0」を厳密に検査できること．
- Julia：REPL，パッケージの有効化とテストの実行，モジュール・`include`・`export`，関数と型パラメータ(`where`)．`eps`・`nextfloat`，`Rational{BigInt}`，`@test`・`@testset`・`@test_throws`．`for`文，タプル，内包表記と`map`・`fill`・`vcat`，ペア(`=>`)．

### 既存のテストへの影響

なし(最初のIteration)．

### 学習者が行うツール操作

- `julia --project=.`でパッケージを有効にしてREPLを起動する．
- REPLのPkgモード(`]`)で`test`を実行する．
- `test/runtests.jl`にテストファイルを`include`で登録する．
- `mise run design <パッケージ>`で設計文書を検査する．

## Iteration 1：二次方程式と後退誤差

### 要件

- 実係数の二次方程式ax² + bx + c = 0(a ≠ 0)の実根を，小さい順に組で返す．実根がなければ`nothing`を返す．重根は同じ値を2つ返す．
- 係数の大きさが極端に違っても(例：b² ≫ |4ac|)，桁落ちせずに両方の根を求める．
- 判別式b² − 4acを，b²と4acが近いときにも正確に計算する．
- a = 0のときと，係数に`Inf`や`NaN`を含むときは`ArgumentError`を投げる．
- 計算した根の後退誤差と，根の条件数を求められる．
- 相対誤差を高精度の参照解(`BigFloat`)とも比べられる．

### 使用例

```julia
julia> quadratic_roots(1.0, 1e8, 1.0)
(-1.0e8, -1.0e-8)

julia> quadratic_roots(1.0, -2.0, 1.0)
(1.0, 1.0)

julia> quadratic_roots(1.0, 0.0, 1.0) === nothing
true

julia> quadratic_roots(94906265.625, -189812534.0, 94906268.375)
(1.0, 1.0000000289759583)

julia> two_prod(0.1, 0.1)
(0.010000000000000002, -8.326672684688674e-19)
```

### モジュール

- `ErrorFreeTransforms`(新規)：`two_sum`を`Summation`から移し，`two_prod(a::T, b::T) where {T<:AbstractFloat}`(fmaによる積の無誤差変換)を加える．
- `Summation`：`two_sum`を`ErrorFreeTransforms`から使う．
- `Quadratic`(新規)
  - `discriminant(a::T, b::T, c::T) where {T<:AbstractFloat}`
  - `quadratic_roots(a::T, b::T, c::T) where {T<:AbstractFloat}`：`Union{Nothing, Tuple{T, T}}`を返す．
  - `root_backward_error(a, b, c, r)`：|p(r)|/(|a|r² + |b||r| + |c|)を返す．
  - `root_condition_number(a, b, c, r)`：(|a|r² + |b||r| + |c|)/|r·p′(r)|を返す．
- `ErrorBounds`：`relative_error(computed::AbstractFloat, exact::BigFloat)`のメソッドを加える．

### リファクタリング

- `two_sum`を新しいモジュール`ErrorFreeTransforms`へ移す．振る舞いは変えない．

### 設計文書の更新

- `design/modules.md`：`ErrorFreeTransforms`と`Quadratic`を加え，`Summation → ErrorFreeTransforms`，`Quadratic → ErrorFreeTransforms`の依存を描く．
- `design/error-spec.md`：`two_prod`，`discriminant`，`quadratic_roots`の行を加える．`quadratic_roots`は前進誤差ではなく後退誤差で誤差界を書き，前進誤差は「条件数 × 後退誤差」で抑える．
- `design/adr/0002-stable-quadratic-formula.md`：根の公式の書き換えと，fmaによる判別式の計算を選んだ理由を書く．

### 学ぶこと

- 数値計算の理論：桁落ち(有害な打ち消し)と無害な打ち消し，根の公式の安定な書き換え，判別式の計算誤差，前進誤差と後退誤差，後退安定性，根の条件数(重根は条件が悪い)，「前進誤差 ≲ 条件数 × 後退誤差」，fmaと積の無誤差変換．
- 品質保証：高精度の参照解に必要な精度の見積もり，特殊値(`Inf`，`NaN`，±0)と境界の検査，解と係数の関係による性質の検査，条件の悪い問題で前進誤差を直接検査しない理由．
- Julia：`fma`・`copysign`・`sqrt`，`nothing`と`Union`，`BigFloat`と`setprecision`，多重ディスパッチ(同じ関数に引数の型の違うメソッドを加える)，`isfinite`，`minmax`．

### 既存のテストへの影響

- `two_sum`のテストを，`test/unit/summation_tests.jl`から`test/unit/error_free_transforms_tests.jl`へ移す．

### 学習者が行うツール操作

- 単体テストだけを実行する(`Pkg.test(test_args = ["unit"])`)．

## Iteration 2：分散と性質ベーステスト

### 要件

- データの平均と標本分散を求める．
- 平均がばらつきより非常に大きいデータ(例：10⁹ + 小さな値)でも，分散を正確に求める．分散は負にならない．
- データを1回走査するだけで分散を求める(Welfordの算法)．
- 比較のため，教科書の公式(Σxᵢ² − (Σxᵢ)²/n)/(n − 1)による分散も計算できる．
- 分散の条件数を求められる．
- 要素数が2未満なら`ArgumentError`を投げる．

### 使用例

```julia
julia> data = [1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16];

julia> mean(data), variance(data), textbook_variance(data)
(1.00000001e9, 30.0, -170.66666666666666)

julia> variance(fill(1e8 + 0.1, 3)), textbook_variance(fill(1e8 + 0.1, 3))
(0.0, 2.0)
```

### モジュール

- `Moments`(新規)
  - `mean(xs::AbstractVector{T}) where {T<:AbstractFloat}`：`compensated_sum`で和を求める．
  - `variance(xs::AbstractVector{T}) where {T<:AbstractFloat}`：Welfordの算法．
  - `textbook_variance(xs::AbstractVector{T}) where {T<:AbstractFloat}`
  - `variance_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat}`：‖x‖₂/√S(Sは偏差平方和)を返す．

### 設計文書の更新

- `design/modules.md`：`Moments`と`Moments → Summation`の依存を加える．
- `design/error-spec.md`：`mean`，`variance`，`textbook_variance`の行を加える．教科書の公式の誤差界がκ²に比例することを書く．
- `design/adr/0003-welford-variance.md`：Welfordの算法を選んだ理由を書く．

### 学ぶこと

- 数値計算の理論：分散の条件数，教科書の公式がκ²で誤差を増やす理由，Welfordの更新式の導出，2の冪による拡大縮小が誤差なく行えること．
- 品質保証：性質ベーステスト(性質を部分的な参照解として使う)，メタモルフィックテスト(平行移動・拡大縮小・並べ替え)，厳密に成り立つ性質と許容誤差つきで成り立つ性質の区別，条件数を制御したテストデータの生成，乱数シードの固定と失敗時の再現．
- Julia：`Random`と`Xoshiro`，`rand`・`randn`，ブロードキャスト(`.+`)，`enumerate`，`@testset`の`for`形式．

### 既存のテストへの影響

なし．

### 学習者が行うツール操作

- `Project.toml`の`[extras]`と`[targets]`を編集し，`Random`をテスト専用の依存に加える．

## Iteration 3：連立1次方程式と後退安定性

### 要件

- 正方行列AのLU分解を求める．既定では部分ピボット選択をし，比較のためにピボット選択なしも選べる．
- LU分解を使って連立1次方程式Ax = bを解く．
- 計算した解の(ノルムによる)後退誤差を求める．
- 分解の増大因子を求める．
- ピボットが0になったら`SingularException`を投げる．

### 使用例

```julia
julia> A = [1e-20 1.0; 1.0 1.0]; b = [1.0, 2.0];

julia> solve(lu_factorize(A; pivot = false), b), solve(lu_factorize(A), b)
([0.0, 1.0], [1.0, 1.0])

julia> backward_error(A, [0.0, 1.0], b), backward_error(A, [1.0, 1.0], b)
(0.25, 0.0)
```

### モジュール

- `LinearSolve`(新規)
  - `struct LUFactorization{T<:AbstractFloat}`：`LU::Matrix{T}`(Lの狭義下三角とUを1つの行列に格納)と`perm::Vector{Int}`を持つ．
  - `lu_factorize(A::AbstractMatrix{T}; pivot::Bool = true) where {T<:AbstractFloat}`
  - `solve(F::LUFactorization{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`
  - `backward_error(A, x, b)`：‖b − Ax‖∞/(‖A‖∞‖x‖∞ + ‖b‖∞)を返す．
  - `growth_factor(F::LUFactorization, A::AbstractMatrix)`：maxᵢⱼ|uᵢⱼ|/maxᵢⱼ|aᵢⱼ|を返す．
- 標準ライブラリ`LinearAlgebra`をパッケージの依存に加える．

### 設計文書の更新

- `design/modules.md`：`LinearSolve`を加える．外部の`LinearAlgebra`への依存は図の外の説明に書く．
- `design/error-spec.md`：`lu_factorize`/`solve`の行を後退誤差で書く(γ₃ₙ·増大因子)．前進誤差は「κ(A) × 後退誤差」で抑える．
- `design/adr/0004-partial-pivoting.md`：部分ピボット選択を既定にした理由と，受け入れ基準を後退誤差にした理由を書く．

### 学ぶこと

- 数値計算の理論：ベクトルと行列のノルム，行列の条件数κ(A)，ノルムによる後退誤差(Rigal–Gaches)，ガウスの消去法の後退誤差解析(Wilkinson)，増大因子，部分ピボット選択の後退安定性，前進誤差の上界κη/(1 − κη)，ヒルベルト行列．
- 品質保証：厳密解を知らなくても残差で後退誤差を検査できること，条件の悪い問題で前進誤差に固定の許容誤差を使うと不合格になる理由，特異値を指定したテスト行列の作り方，分解の再構成(PA ≈ LU)の検査．
- Julia：`struct`とパラメータ型，キーワード引数，行列の添字とスライス，`@views`，破壊的な関数の`!`の命名規約，`LinearAlgebra`の`norm`・`opnorm`・`cond`，例外．

### 既存のテストへの影響

なし．

### 学習者が行うツール操作

- Pkgモードの`add`で`LinearAlgebra`を依存に加える．

## Iteration 4：最小二乗法と直交変換

### 要件

- 列フルランクの縦長行列Aについて，最小二乗問題min‖Ax − b‖₂を解く．
- ハウスホルダー変換によるQR分解で解く．
- 比較のため，正規方程式AᵀAx = Aᵀbでも解ける．
- 多項式の当てはめ(多項式の係数を最小二乗で求める)ができる．
- 行数が列数より少なければ`ArgumentError`を投げる．

### 使用例

```julia
julia> t = range(0, 1; length = 50); V = [ti^j for ti in t, j in 0:9]; y = V * ones(10);

julia> maximum(abs, lstsq_qr(V, y) .- 1), maximum(abs, lstsq_normal(V, y) .- 1)
(2.912133867383204e-10, 3.0555489688333104e-5)

julia> polyfit([0.0, 1.0, 2.0, 3.0], [1.0, 3.0, 5.0, 7.0], 1)
2-element Vector{Float64}:
 1.0000000000000002
 1.9999999999999996
```

### モジュール

- `Triangular`(新規)：`LinearSolve.solve`の前進代入と後退代入を取り出す．
  - `forward_substitution(L::AbstractMatrix{T}, b::AbstractVector{T}; unit_diagonal::Bool = false) where {T<:AbstractFloat}`
  - `back_substitution(U::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}`
- `LinearSolve`：`solve`が`Triangular`を使う．
- `LeastSquares`(新規)
  - `struct QRFactorization{T<:AbstractFloat}`：ハウスホルダーベクトルとRを持つ．
  - `householder_qr(A::AbstractMatrix{T}) where {T<:AbstractFloat}`
  - `lstsq_qr(A, b)`
  - `lstsq_normal(A, b)`：`LinearSolve`のLU分解で正規方程式を解く．
  - `polyfit(t, y, degree::Integer)`

### リファクタリング

- 前進代入と後退代入を`LinearSolve`から`Triangular`へ移す．振る舞いは変えない．

### 設計文書の更新

- `design/modules.md`：`Triangular`と`LeastSquares`を加え，`LinearSolve → Triangular`，`LeastSquares → Triangular`，`LeastSquares → LinearSolve`の依存を描く．
- `design/error-spec.md`：`lstsq_qr`と`lstsq_normal`の行を加え，前進誤差の上界がそれぞれκ₂と κ₂²に比例することを書く．
- `design/adr/0005-householder-qr.md`：最小二乗法にハウスホルダーQR分解を選んだ理由を書く．

### 学ぶこと

- 数値計算の理論：2ノルムと特異値，κ₂(A)，正規方程式で条件数が2乗になる理由，直交変換が誤差を増やさない理由，ハウスホルダー変換，最小二乗問題の感度(残差の大きさの影響)．
- 品質保証：製造解の方法(先に決めた解`x`と，値域に直交する残差`r`から，問題`b = A*x + r`を作る)，最適性条件Aᵀr ≈ 0の検査，直交性‖QᵀQ − I‖の検査，リファクタリングの前後で同じテストが通ることによる保証．
- Julia：転置(`transpose`，`'`)，外積，`size`，部分行列の更新，構造体を返す関数．

### 既存のテストへの影響

- `LinearSolve`の単体テストは変えずに通る(リファクタリングの安全網)．
- `test/unit/triangular_tests.jl`を新しく作る．

### 学習者が行うツール操作

- 特定のテストファイルだけをREPLから`include`して実行する．

## Iteration 5：指数関数とULP精度

### 要件

- `Float64`の指数関数exp(x)を，誤差1 ULP未満で計算する．
- `NaN`は`NaN`，`Inf`は`Inf`，`-Inf`は`0.0`を返す．
- 結果が`Float64`の最大値を超える引数では`Inf`を返し，非常に小さい結果は非正規化数または`0.0`になる．
- 計算結果のULP誤差を，高精度の参照解と比べて求められる．

### 使用例

```julia
julia> exponential(1.0), exponential(-Inf), exponential(710.0)
(2.718281828459045, 0.0, Inf)

julia> ulp_error(exponential(0.5), exp(big(0.5)))
0.21309090040865203
```

### モジュール

- `ElementaryFunctions`(新規)
  - `reduce_argument(x::Float64)`：x = k·ln 2 + r(|r| ≤ ln 2/2)となる`(k, r)`を返す(Cody–Waiteの方法)．
  - `exponential(x::Float64)`
- `ErrorBounds`：`ulp_error(computed::AbstractFloat, exact::BigFloat)`を加える．

### 設計文書の更新

- `design/modules.md`：`ElementaryFunctions`を加える．
- `design/error-spec.md`：`exponential`の行を，還元・多項式近似・評価・復元の誤差予算の内訳とともに書く．
- `design/adr/0006-exp-range-reduction.md`：引数還元と多項式の次数を決めた理由を書く．

### 学ぶこと

- 数値計算の理論：ULP誤差，正しい丸めと忠実な丸め，引数還元(Cody–Waite)，テイラー多項式の打ち切り誤差，ホーナー法の丸め誤差，誤差予算，オーバーフローとアンダーフロー，テーブルメーカーのジレンマ．
- 品質保証：ULPによる精度の保証，乱数による標本検査・境界値検査・連続する浮動小数点数の局所的な全数検査・既存実装との差分テストの組み合わせ，単調性などの性質の検査．
- Julia：`ldexp`・`round`，`evalpoly`，`nextfloat`・`prevfloat`による浮動小数点数の列挙，`reinterpret`によるビット列の観察．

### 既存のテストへの影響

なし．

### 学習者が行うツール操作

- 時間のかかる検査(局所的な全数検査)をテストグループに分け，個別に実行する．
