"""
    StableNumerics

浮動小数点数の計算を，誤差の理論に基づいて安定に行う関数を集めたパッケージ．
"""
module StableNumerics

include("ErrorBounds.jl")
include("ErrorFreeTransforms.jl")
include("Summation.jl")
include("Quadratic.jl")

using .ErrorBounds
using .ErrorFreeTransforms
using .Summation
using .Quadratic

export unit_roundoff, gamma, relative_error
export two_sum, two_prod
export naive_sum, compensated_sum, sum_condition_number
export discriminant, quadratic_roots, root_backward_error, root_condition_number

end
