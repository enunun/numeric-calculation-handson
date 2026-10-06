using LinearAlgebra
using Random
using StableNumerics.ErrorBounds
using StableNumerics.LinearSolve

@testset "LinearSolve" begin
    @testset "lu_factorize" begin
        # [2 1; 4 3]：2行目をピボットに選び，l = 0.5，u₂₂ = 1 - 0.5 × 3 = -0.5．どの計算も丸めない．
        F = lu_factorize([2.0 1.0; 4.0 3.0])
        @test F.LU == [4.0 3.0; 0.5 -0.5]
        @test F.perm == [2, 1]
        G = lu_factorize([2.0 1.0; 4.0 3.0]; pivot = false)
        @test G.LU == [2.0 1.0; 2.0 1.0]
        @test G.perm == [1, 2]
        @test_throws SingularException lu_factorize([1.0 2.0; 2.0 4.0])
        @test_throws SingularException lu_factorize([0.0 1.0; 1.0 0.0]; pivot = false)
        @test lu_factorize([0.0 1.0; 1.0 0.0]).perm == [2, 1]
        @test_throws DimensionMismatch lu_factorize(ones(2, 3))
    end

    @testset "lu_factorize：分解の後退誤差 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:12)
        A = matrix_with_condition(rng, n, 10.0^rand(rng, 0:12))
        F = lu_factorize(A)
        L = Rational{BigInt}.(tril(F.LU, -1) + I)
        U = Rational{BigInt}.(triu(F.LU))
        # 部分ピボット選択では，Lの要素の絶対値は1以下になる．
        @test all(abs.(tril(F.LU, -1)) .<= 1)
        # 誤差界：|PA - L̂Û| ≤ γₙ|L̂||Û|が要素ごとに成り立つ．
        residual = abs.(Rational{BigInt}.(A[F.perm, :]) - L * U)
        @test all(residual .<= gamma(n, Float64) .* (abs.(L) * abs.(U)))
    end

    @testset "solve" begin
        # 2x + y = 3，4x + 3y = 7の解はx = y = 1．どの計算も丸めない．
        @test solve(lu_factorize([2.0 1.0; 4.0 3.0]), [3.0, 7.0]) == [1.0, 1.0]
        A = [1e-20 1.0; 1.0 1.0]
        b = [1.0, 2.0]
        # ピボット選択なしでは，乗数l = 10²⁰が大きく，x₁の情報が失われる．
        @test solve(lu_factorize(A; pivot = false), b) == [0.0, 1.0]
        @test solve(lu_factorize(A), b) == [1.0, 1.0]
        @test_throws DimensionMismatch solve(lu_factorize([2.0 1.0; 4.0 3.0]), [1.0, 2.0, 3.0])
    end

    @testset "solve：誤差界 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:12)
        A = matrix_with_condition(rng, n, 10.0^rand(rng, 0:12))
        b = A * randn(rng, n)
        F = lu_factorize(A)
        x = solve(F, b)
        η = backward_error(A, x, b)
        # 後退誤差 ≤ γ₃ₙ‖|L̂||Û|‖∞/‖A‖∞(Wilkinsonの解析)．
        @test η <= lu_backward_error_bound(F, A)
        # 前進誤差 ≤ 2κη/(1 - κη)(κは∞ノルムの条件数)．
        κ = exact_matrix_condition_number(A)
        @test forward_error(x, A, b) <= 2κ * η / (1 - κ * η)
    end

    @testset "solve：ヒルベルト行列" begin
        A = hilbert_matrix(10)
        b = A * ones(10)
        F = lu_factorize(A)
        x = solve(F, b)
        η = backward_error(A, x, b)
        κ = exact_matrix_condition_number(A)
        @test η <= lu_backward_error_bound(F, A)
        @test forward_error(x, A, b) <= 2κ * η / (1 - κ * η)
        # 後退誤差は単位丸め程度でも，条件数が10¹³を超えるので，前進誤差は大きい．
        # 前進誤差を後退誤差の上界(γ₃ₙ程度)で検査すると，正しい実装が不合格になる．
        @test κ > 1e13
        @test forward_error(x, A, b) > gamma(3 * 10, Float64)
    end

    @testset "backward_error" begin
        A = [1e-20 1.0; 1.0 1.0]
        b = [1.0, 2.0]
        # 残差b - Ax = (0, 1)，‖A‖∞ = 2，‖x‖∞ = 1，‖b‖∞ = 2なので，1/(2 + 2) = 0.25．
        @test backward_error(A, [0.0, 1.0], b) == 0.25
        # (1, 1)は厳密解ではない．残差は(-10⁻²⁰, 0)で，浮動小数点数で計算すると0になるが，有理数で計算すると現れる．
        @test backward_error(A, [1.0, 1.0], b) == 1e-20 / 4
        @test backward_error([2.0 1.0; 4.0 3.0], [1.0, 1.0], [3.0, 7.0]) == 0.0
    end

    @testset "growth_factor" begin
        A = [2.0 1.0; 4.0 3.0]
        # Uの要素の最大値は4，Aの要素の最大値も4．
        @test growth_factor(lu_factorize(A), A) == 1.0
        # ピボット選択なしの[1e-20 1; 1 1]では，u₂₂ = 1 - 10²⁰が現れる．
        B = [1e-20 1.0; 1.0 1.0]
        @test growth_factor(lu_factorize(B; pivot = false), B) == 1e20
        for n in (5, 10, 20)
            W = wilkinson_growth_matrix(n)
            @test growth_factor(lu_factorize(W), W) == 2.0^(n - 1)
        end
    end
end
