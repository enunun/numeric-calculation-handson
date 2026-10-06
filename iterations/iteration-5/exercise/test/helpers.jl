# テストで使う参照解とテストデータ．

using LinearAlgebra
using Random

"""
    exact_sum(xs)

浮動小数点数のベクトルの総和を，有理数で厳密に求める．
"""
function exact_sum(xs)
    s = Rational{BigInt}(0)
    for x in xs
        s += Rational{BigInt}(x)
    end
    return s
end

"""
    exact_condition_number(xs)

総和の条件数Σ|xᵢ|/|Σxᵢ|を有理数で厳密に求め，`Float64`で返す．
"""
function exact_condition_number(xs)
    return Float64(exact_sum(map(abs, xs)) / abs(exact_sum(xs)))
end

# 無誤差変換の検査に使う組．大きさと符号の違う組を選んである．
const EFT_PAIRS = [(0.1, 0.2), (1e16, 1.0), (1.0, -1e-17), (-3.5, 1e-300), (2.0^60, -3.0), (1.0 + 2.0^-52, 1.0 - 2.0^-53)]

# 誤差界の検査に使うデータ．条件数が1から10¹⁶程度まで広がるように選んである．
const SUM_DATASETS = [
    "0.1を1000個" => fill(0.1, 1000),
    "調和級数1/k" => [1 / k for k in 1:1000],
    "交代級数(-1)^k/k" => [(-1)^k / k for k in 1:1000],
    "大きな値の打ち消し" => [1e16, 1.0, -1e16],
    "近い値の差" => vcat([1e10 + k for k in 1:100], [-(1e10 + k) + 1e-3 for k in 1:100]),
]

"""
    exact_discriminant(a, b, c)

判別式b² - 4acを有理数で厳密に求める．
"""
function exact_discriminant(a, b, c)
    A, B, C = Rational{BigInt}(a), Rational{BigInt}(b), Rational{BigInt}(c)
    return B^2 - 4 * A * C
end

"""
    reference_roots(a, b, c; precision = 256)

二次方程式の実根を，判別式を有理数で厳密に求めたうえで，`precision`ビットの`BigFloat`で根の公式から計算する．
実根がなければ`nothing`を返す．
"""
function reference_roots(a, b, c; precision = 256)
    d = exact_discriminant(a, b, c)
    d < 0 && return nothing
    return setprecision(BigFloat, precision) do
        s = sqrt(BigFloat(d))
        A, B = BigFloat(a), BigFloat(b)
        minmax((-B - s) / (2A), (-B + s) / (2A))
    end
end

# 二次方程式の検査に使う係数．
# 桁落ちしやすい係数，重根，根が0の場合，判別式が0に近い場合(Kahanの例と，根が1.5と1.5(1 + δ)の場合)を含む．
# δ = 1e-8では，係数を丸めた結果，厳密な判別式が負になる(実根がない)．
const QUADRATIC_CASES = [
    (1.0, -3.0, 2.0),
    (-1.0, 3.0, -2.0),
    (1.0, 1e8, 1.0),
    (1.0, -1e8, 1.0),
    (1e-10, 1.0, 1e-10),
    (2.0, 3.0, 0.0),
    (1.0, 0.0, 0.0),
    (1.0, -0.0, -4.0),
    (1.0, -2.0, 1.0),
    (1.0, 0.0, 1.0),
    (1.0, -2.0, 1.0 + 2.0^-52),
    (94906265.625, -189812534.0, 94906268.375),
    [(1.0, -(1.5 + 1.5 * (1 + δ)), 1.5 * (1.5 * (1 + δ))) for δ in (1e-4, 1e-7, 1e-8, 1e-10, 1e-12)]...,
]

"""
    exact_deviation_sum(xs)

偏差平方和S = Σ(xᵢ - x̄)² = Σxᵢ² - (Σxᵢ)²/nを有理数で厳密に求める．
"""
function exact_deviation_sum(xs)
    n = length(xs)
    total = exact_sum(xs)
    squares = sum(Rational{BigInt}(x)^2 for x in xs)
    return squares - total^2 / n
end

"""
    exact_variance(xs)

標本分散S/(n - 1)を有理数で厳密に求める．
"""
exact_variance(xs) = exact_deviation_sum(xs) / (length(xs) - 1)

"""
    exact_variance_condition_number(xs)

分散の条件数‖x‖₂/√Sを求める．‖x‖₂²とSは有理数で厳密に求め，平方根は`BigFloat`で計算する．
"""
function exact_variance_condition_number(xs)
    squares = sum(Rational{BigInt}(x)^2 for x in xs)
    return Float64(sqrt(BigFloat(squares / exact_deviation_sum(xs))))
end

"""
    shifted_normal_data(rng, n; center, spread)

平均center，標準偏差spreadの正規分布に従うn個のデータを返す．
条件数はおよそ|center|/spreadになる．
"""
shifted_normal_data(rng, n; center, spread) = center .+ spread .* randn(rng, n)

"""
    integer_data(rng, n)

-4000から4000程度の整数値のデータを返す．大きな整数を足しても丸めが起きないので，平行移動の検査に使う．
"""
integer_data(rng, n) = round.(1000 .* randn(rng, n))

# 性質ベーステストで使う乱数のシード．テストが失敗したら，@testsetの名前に表示されるシードでデータを再現できる．
const SEEDS = 1:50

# 連立1次方程式の参照解．行列とベクトルを有理数に直し，丸め誤差なしで計算する．

"""
    infinity_norm(A)

行列の∞ノルム(行ごとの絶対値の和の最大値)．有理数の行列にも使える．
"""
infinity_norm(A::AbstractMatrix) = maximum(sum(abs, A; dims = 2))

"""
    exact_solution(A, b)

Ax = bの厳密解を有理数で求める．
"""
exact_solution(A, b) = Rational{BigInt}.(A) \ Rational{BigInt}.(b)

"""
    exact_matrix_condition_number(A)

行列の∞ノルムの条件数‖A‖∞‖A⁻¹‖∞を有理数で厳密に求め，`Float64`で返す．
"""
function exact_matrix_condition_number(A)
    Q = Rational{BigInt}.(A)
    return Float64(infinity_norm(Q) * infinity_norm(inv(Q)))
end

"""
    forward_error(x, A, b)

計算した解xの相対誤差‖x - x*‖∞/‖x*‖∞を，厳密解x*と比べて求める．
"""
function forward_error(x, A, b)
    exact = exact_solution(A, b)
    return Float64(maximum(abs, Rational{BigInt}.(x) - exact) / maximum(abs, exact))
end

"""
    lu_backward_error_bound(F, A)

LU分解で解いた解の後退誤差の上界γ₃ₙ‖|L̂||Û|‖∞/‖A‖∞を返す(Wilkinsonの解析)．
|L̂||Û|と∞ノルムは有理数で厳密に求める．
"""
function lu_backward_error_bound(F, A)
    n = size(A, 1)
    L = Rational{BigInt}.(tril(F.LU, -1) + I)
    U = Rational{BigInt}.(triu(F.LU))
    ratio = infinity_norm(abs.(L) * abs.(U)) / infinity_norm(Rational{BigInt}.(A))
    return gamma(3n, Float64) * Float64(ratio)
end

"""
    matrix_with_condition(rng, m, n, κ)

特異値が1からκ⁻¹まで等比的に並ぶm × n行列(m ≥ n)UΣVᵀを返す．
Uは正規直交なn本の列，Vは直交行列で，どちらも乱数の行列のQR分解で作る．
2ノルムの条件数はおよそκになる(行列の要素を丸めるので，厳密にκではない)．
"""
function matrix_with_condition(rng, m, n, κ)
    U = Matrix(qr(randn(rng, m, m)).Q)[:, 1:n]
    V = Matrix(qr(randn(rng, n, n)).Q)
    σ = [κ^(-(i - 1) / (n - 1)) for i in 1:n]
    return U * Diagonal(σ) * V'
end

"""
    matrix_with_condition(rng, n, κ)

条件数がおよそκのn × n行列を返す．
"""
matrix_with_condition(rng, n, κ) = matrix_with_condition(rng, n, n, κ)

"""
    hilbert_matrix(n)

ヒルベルト行列(i, j要素が1/(i + j - 1))．条件数が非常に大きい行列の例である．
"""
hilbert_matrix(n) = [1 / (i + j - 1) for i in 1:n, j in 1:n]

"""
    wilkinson_growth_matrix(n)

部分ピボット選択の増大因子が2ⁿ⁻¹になる行列．対角が1，対角より下が-1，最後の列が1である．
"""
function wilkinson_growth_matrix(n)
    A = [i == j ? 1.0 : (i > j ? -1.0 : 0.0) for i in 1:n, j in 1:n]
    A[:, end] .= 1.0
    return A
end

"""
    componentwise_backward_error(A, x, b)

成分ごとの後退誤差maxᵢ|b - Ax|ᵢ/(|A||x|)ᵢを有理数で厳密に求める(Oettli–Prager，bは変えない場合)．
(|A||x|)ᵢ = 0の成分は，残差も0なら無視し，そうでなければ`Inf`を返す．
"""
function componentwise_backward_error(A, x, b)
    Q, y, c = Rational{BigInt}.(A), Rational{BigInt}.(x), Rational{BigInt}.(b)
    residual = abs.(c - Q * y)
    scale = abs.(Q) * abs.(y)
    worst = Rational{BigInt}(0)
    for i in eachindex(residual)
        if iszero(scale[i])
            iszero(residual[i]) || return Inf
        else
            worst = max(worst, residual[i] / scale[i])
        end
    end
    return Float64(worst)
end

# 最小二乗問題の参照解とテストデータ．

"""
    exact_least_squares(A, b)

最小二乗問題min‖Ax - b‖₂の解を，正規方程式AᵀAx = Aᵀbを有理数で解いて厳密に求める．
"""
function exact_least_squares(A, b)
    Q = Rational{BigInt}.(A)
    return (transpose(Q) * Q) \ (transpose(Q) * Rational{BigInt}.(b))
end

"""
    relative_error_2norm(x, exact)

相対誤差‖x - exact‖₂/‖exact‖₂．差は有理数で厳密に求め，ノルムは`Float64`で計算する．
"""
function relative_error_2norm(x, exact)
    difference = Float64.(Rational{BigInt}.(x) - exact)
    return norm(difference) / norm(Float64.(exact))
end

"""
    hadamard(m)

m × mのアダマール行列(要素は±1，列どうしが直交する)．mは2の冪である(シルベスターの構成)．
"""
hadamard(m) = m == 1 ? ones(1, 1) : (H = hadamard(m ÷ 2); [H H; H -H])

"""
    pascal_upper(n)

上三角のパスカル行列(i, j要素が二項係数C(j - 1, i - 1))．行列式は1で，nとともに条件数が大きくなる．
"""
pascal_upper(n) = [Float64(binomial(j - 1, i - 1)) for i in 1:n, j in 1:n]

"""
    manufactured_least_squares(rng, m, n)

答えのわかっている最小二乗問題を作る(製造解)．`(A, x, b, r)`を返す．
アダマール行列Hの最初のn列にパスカル行列を掛けてAを作り，整数のベクトルxと，
Hの残りの列の整数係数の組み合わせr(Aのどの列とも厳密に直交する)からb = Ax + rを作る．
どの値も小さな整数なので丸めずに表せ，最小二乗解は厳密にx，残差は厳密にrである．
"""
function manufactured_least_squares(rng, m, n)
    H = hadamard(m)
    A = H[:, 1:n] * pascal_upper(n)
    x = Float64.(rand(rng, -5:5, n))
    r = H[:, n+1:m] * Float64.(rand(rng, -5:5, m - n))
    return A, x, A * x + r, r
end

"""
    least_squares_tolerance(A, x, r)

最小二乗解の前進誤差の許容誤差γ₂ₘₙ(κ₂ + κ₂²ρ)を返す．ρ = ‖r‖₂/(‖A‖₂‖x‖₂)，κ₂は`cond`で求めた2ノルムの条件数である．
"""
function least_squares_tolerance(A, x, r)
    m, n = size(A)
    κ = cond(A)
    ρ = norm(r) / (opnorm(A) * norm(x))
    return gamma(2m * n, Float64) * (κ + κ^2 * ρ)
end
