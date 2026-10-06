"""
    StableNumerics

浮動小数点数の計算を，誤差の理論に基づいて安定に行う関数を集めたパッケージ．
"""
module StableNumerics

include("ErrorBounds.jl")
include("Summation.jl")

using .ErrorBounds
using .Summation

export unit_roundoff, gamma, relative_error
export two_sum, naive_sum, compensated_sum, sum_condition_number

end
