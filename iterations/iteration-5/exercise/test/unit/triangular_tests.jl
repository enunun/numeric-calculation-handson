using LinearAlgebra
using Random
using StableNumerics.ErrorBounds
using StableNumerics.Triangular

@testset "Triangular" begin
    @testset "forward_substitution" begin
        # 2x₁ = 4，x₁ + 4x₂ = 10の解は(2, 2)．どの計算も丸めない．
        @test forward_substitution([2.0 0.0; 1.0 4.0], [4.0, 10.0]) == [2.0, 2.0]
        # unit_diagonal = trueでは対角を1とみなし，対角と上の要素は読まない．
        @test forward_substitution([9.0 9.0; 0.5 9.0], [1.0, 2.0]; unit_diagonal = true) == [1.0, 1.5]
        @test_throws SingularException forward_substitution([0.0 0.0; 1.0 1.0], [1.0, 1.0])
        @test_throws DimensionMismatch forward_substitution([1.0 0.0; 1.0 1.0], [1.0])
    end

    @testset "back_substitution" begin
        # 2x₁ + x₂ = 5，4x₂ = 8の解は(1.5, 2)．どの計算も丸めない．
        @test back_substitution([2.0 1.0; 0.0 4.0], [5.0, 8.0]) == [1.5, 2.0]
        # 対角より下の要素は読まない．
        @test back_substitution([2.0 1.0; 7.0 4.0], [5.0, 8.0]) == [1.5, 2.0]
        @test_throws SingularException back_substitution([1.0 1.0; 0.0 0.0], [1.0, 1.0])
        @test_throws DimensionMismatch back_substitution([1.0 1.0; 0.0 1.0], [1.0, 2.0, 3.0])
    end

    @testset "成分ごとの後退誤差 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:20)
        T = triu(matrix_with_condition(rng, n, 10.0^rand(rng, 0:8)))
        b = randn(rng, n)
        # 誤差界：(T + ΔT)x̂ = b，|ΔT| ≤ γₙ|T|．成分ごとの後退誤差maxᵢ|b - Tx̂|ᵢ/(|T||x̂|)ᵢがγₙ以下になる．
        @test componentwise_backward_error(T, back_substitution(T, b), b) <= gamma(n, Float64)
        L = Matrix(transpose(T))
        @test componentwise_backward_error(L, forward_substitution(L, b), b) <= gamma(n, Float64)
    end
end
