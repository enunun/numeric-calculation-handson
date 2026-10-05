using Test
using StableNumerics

# Pkg.test(test_args = ["unit"])のように，実行するテストのグループを引数で選べる．
const GROUPS = isempty(ARGS) ? ["unit", "integration"] : ARGS

include("helpers.jl")

@testset "StableNumerics" begin
    if "unit" in GROUPS
        @testset "unit" begin
            include("unit/error_bounds_tests.jl")
            include("unit/summation_tests.jl")
        end
    end
    if "integration" in GROUPS
        @testset "integration" begin
            include("integration/summation_accuracy_tests.jl")
        end
    end
end
