# テストで使う参照解．有理数で計算するので，丸め誤差を含まない．

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
