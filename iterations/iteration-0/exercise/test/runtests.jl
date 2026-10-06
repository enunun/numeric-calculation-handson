using Test
using StableNumerics

# Pkg.test(test_args = ["unit"])のように，実行するテストのグループを引数で選べる．
const GROUPS = isempty(ARGS) ? ["unit", "integration"] : ARGS

@testset "StableNumerics" begin
    if "unit" in GROUPS
        @testset "unit" begin
        end
    end
    if "integration" in GROUPS
        @testset "integration" begin
        end
    end
end
