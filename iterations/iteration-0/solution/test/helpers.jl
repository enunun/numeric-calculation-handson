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

# 誤差界の検査に使うデータ．条件数が1から10¹⁶程度まで広がるように選んである．
const SUM_DATASETS = [
    "0.1を1000個" => fill(0.1, 1000),
    "調和級数1/k" => [1 / k for k in 1:1000],
    "交代級数(-1)^k/k" => [(-1)^k / k for k in 1:1000],
    "大きな値の打ち消し" => [1e16, 1.0, -1e16],
    "近い値の差" => vcat([1e10 + k for k in 1:100], [-(1e10 + k) + 1e-3 for k in 1:100]),
]
