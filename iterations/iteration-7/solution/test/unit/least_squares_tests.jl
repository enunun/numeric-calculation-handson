using LinearAlgebra
using Random
using StableNumerics.ErrorBounds
using StableNumerics.LeastSquares

@testset "LeastSquares" begin
    @testset "householder_qr" begin
        A = [3.0 1.0; 4.0 2.0; 0.0 5.0]
        F = householder_qr(A)
        @test size(F.R) == (2, 2)
        @test F.R[2, 1] == 0
        @test size(q_factor(F)) == (3, 2)
        @test_throws ArgumentError householder_qr(ones(2, 3))
    end

    @testset "householder_qr：列がe₁にほぼ平行な行列" begin
        # 列の最初の要素が他よりずっと大きいとき，αの符号を誤るとvₖ = x - αe₁の計算で桁落ちが起きる．
        # 乱数の行列ではまず起きないので，このような列を狙って作る．
        for sign in (1.0, -1.0), ε in (1e-4, 1e-8, 1e-12)
            A = [sign 1.0; ε 2.0; ε 3.0; ε 4.0]
            m, n = size(A)
            F = householder_qr(A)
            Q = Rational{BigInt}.(q_factor(F))
            tolerance = gamma(2m * n, Float64)
            @test opnorm(Float64.(transpose(Q) * Q - I)) <= tolerance
            difference = Float64.(Rational{BigInt}.(A) - Q * Rational{BigInt}.(F.R))
            @test all(norm(difference[:, j]) <= tolerance * norm(A[:, j]) for j in 1:n)
        end
    end

    @testset "householder_qr：直交性と再構成 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        m = rand(rng, 3:30)
        n = rand(rng, 2:min(m, 8))
        A = matrix_with_condition(rng, m, n, 10.0^rand(rng, 0:10))
        F = householder_qr(A)
        Q = Rational{BigInt}.(q_factor(F))
        R = Rational{BigInt}.(F.R)
        tolerance = gamma(2m * n, Float64)
        # Q̂の列はほぼ正規直交：‖Q̂ᵀQ̂ - I‖₂ ≤ γ₂ₘₙ(一次の見積もりに2倍の余裕)．
        @test opnorm(Float64.(transpose(Q) * Q - I)) <= tolerance
        # A ≈ Q̂R̂：列ごとに‖aⱼ - (Q̂R̂)ⱼ‖₂ ≤ γ₂ₘₙ‖aⱼ‖₂．
        difference = Float64.(Rational{BigInt}.(A) - Q * R)
        @test all(norm(difference[:, j]) <= tolerance * norm(A[:, j]) for j in 1:n)
    end

    @testset "lstsq_qr" begin
        # 2列目が0の行列は列フルランクではない．
        @test_throws SingularException lstsq_qr([1.0 0.0; 1.0 0.0; 1.0 0.0], [1.0, 2.0, 3.0])
        @test_throws ArgumentError lstsq_qr(ones(2, 3), [1.0, 2.0])
    end

    @testset "lstsq_qr：製造解 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        m = rand(rng, (8, 16, 32))
        n = rand(rng, 2:min(m - 1, 10))
        A, x, b, r = manufactured_least_squares(rng, m, n)
        # 製造した残差は，Aの列と厳密に直交している．
        @test transpose(A) * r == zeros(n)
        # 前進誤差 ≤ γ₂ₘₙ(κ₂ + κ₂²ρ)．
        @test norm(lstsq_qr(A, b) - x) / norm(x) <= least_squares_tolerance(A, x, r)
    end

    @testset "lstsq_qr：誤差界と最適性 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        m = rand(rng, 3:30)
        n = rand(rng, 2:min(m - 1, 8))
        A = matrix_with_condition(rng, m, n, 10.0^rand(rng, 0:10))
        b = A * randn(rng, n) + 10.0^rand(rng, -8:0) * randn(rng, m)
        exact = exact_least_squares(A, b)
        exact_residual = Float64.(Rational{BigInt}.(b) - Rational{BigInt}.(A) * exact)
        x = lstsq_qr(A, b)
        @test relative_error_2norm(x, exact) <= least_squares_tolerance(A, Float64.(exact), exact_residual)
        # 最適性条件：Aᵀr̂ ≈ 0．‖Aᵀr̂‖₂ ≤ γ₂ₘₙ‖A‖₂(‖A‖₂‖x̂‖₂ + ‖b‖₂ + ‖r̂‖₂)．r̂は有理数で求める．
        residual = Rational{BigInt}.(b) - Rational{BigInt}.(A) * Rational{BigInt}.(x)
        scale = opnorm(A) * (opnorm(A) * norm(x) + norm(b) + norm(Float64.(residual)))
        @test norm(Float64.(transpose(Rational{BigInt}.(A)) * residual)) <= gamma(2m * n, Float64) * scale
    end

    @testset "lstsq_normal：誤差界 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        m = rand(rng, (8, 16, 32))
        n = rand(rng, 2:min(m - 1, 10))
        A, x, b, r = manufactured_least_squares(rng, m, n)
        # 前進誤差 ≤ γ₂ₘₙκ₂²(一次の見積もりに2倍の余裕)．κ₂²u ≪ 1の行列だけで成り立つ．
        @test norm(lstsq_normal(A, b) - x) / norm(x) <= gamma(2m * n, Float64) * cond(A)^2
    end

    @testset "polyfit" begin
        @test_throws ArgumentError polyfit([0.0, 1.0], [1.0, 2.0], 2)
        # 整数の点で整数係数の多項式の値をとると，データは丸めずに表せ，係数が厳密な最小二乗解になる(製造解)．
        t = Float64.(0:19)
        for degree in 1:5
            coefficients = Float64.(collect(1:degree+1) .* (-1) .^ (0:degree))
            y = [sum(coefficients[j+1] * ti^j for j in 0:degree) for ti in t]
            V = [ti^j for ti in t, j in 0:degree]
            @test norm(polyfit(t, y, degree) - coefficients) / norm(coefficients) <= gamma(2 * length(t) * (degree + 1), Float64) * cond(V)
        end
    end
end
