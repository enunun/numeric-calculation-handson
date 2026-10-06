using Test
using StableNumerics

# Pkg.test(test_args = ["unit"])のように，実行するテストのグループを引数で選べる．
# exhaustiveは時間のかかる局所的な全数検査で，Pkg.test(test_args = ["exhaustive"])で単独でも実行できる．
const GROUPS = isempty(ARGS) ? ["unit", "integration", "exhaustive"] : ARGS

include("helpers.jl")

@testset "StableNumerics" begin
    if "unit" in GROUPS
        @testset "unit" begin
            include("unit/error_bounds_tests.jl")
            include("unit/error_free_transforms_tests.jl")
            include("unit/summation_tests.jl")
            include("unit/quadratic_tests.jl")
            include("unit/moments_tests.jl")
            include("unit/triangular_tests.jl")
            include("unit/linear_solve_tests.jl")
            include("unit/least_squares_tests.jl")
            include("unit/elementary_functions_tests.jl")
            include("unit/ode_solvers_tests.jl")
        end
    end
    if "integration" in GROUPS
        @testset "integration" begin
            include("integration/summation_accuracy_tests.jl")
            include("integration/quadratic_quality_tests.jl")
            include("integration/variance_accuracy_tests.jl")
            include("integration/pivoting_tests.jl")
            include("integration/least_squares_methods_tests.jl")
            include("integration/ode_convergence_tests.jl")
        end
    end
    if "exhaustive" in GROUPS
        @testset "exhaustive" begin
            include("exhaustive/exponential_exhaustive_tests.jl")
        end
    end
end
