"""
    StableNumerics

浮動小数点数の計算を，誤差の理論に基づいて安定に行う関数を集めたパッケージ．
"""
module StableNumerics

include("ErrorBounds.jl")
include("ErrorFreeTransforms.jl")
include("Summation.jl")
include("Quadratic.jl")
include("Moments.jl")
include("Triangular.jl")
include("LinearSolve.jl")
include("LeastSquares.jl")
include("ElementaryFunctions.jl")
include("ODESolvers.jl")
include("Hamiltonian.jl")

using .ErrorBounds
using .ErrorFreeTransforms
using .Summation
using .Quadratic
using .Moments
using .Triangular
using .LinearSolve
using .LeastSquares
using .ElementaryFunctions
using .ODESolvers
using .Hamiltonian

export unit_roundoff, gamma, relative_error, ulp_error
export two_sum, two_prod
export naive_sum, compensated_sum, sum_condition_number
export discriminant, quadratic_roots, root_backward_error, root_condition_number
export mean, variance, textbook_variance, variance_condition_number
export forward_substitution, back_substitution
export LUFactorization, lu_factorize, solve, backward_error, growth_factor
export QRFactorization, householder_qr, q_factor, lstsq_qr, lstsq_normal, polyfit
export reduce_argument, exponential
export euler_step, rk4_step, integrate, observed_order, richardson_error_estimate
export bs32_step, integrate_adaptive
export verlet_step, verlet_integrate

end
