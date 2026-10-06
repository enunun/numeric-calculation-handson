using Random
using StableNumerics.ErrorBounds
using StableNumerics.Moments

# Welfordの算法の許容誤差：一次の見積もりnκuに2倍の余裕を持たせたγ₂ₙ·κ(誤差仕様書)．
welford_tolerance(xs, κ) = gamma(2 * length(xs), Float64) * κ

@testset "Moments" begin
    @testset "mean" begin
        @test mean([1.0, 2.0, 3.0, 4.0]) == 2.5
        @test mean([1e16, 1.0, -1e16]) == 1 / 3
        @test_throws ArgumentError mean(Float64[])
        # 誤差界：相対誤差 ≤ (1 + β)(1 + u) - 1 = β + u + βu(β = u + γₙ₋₁²κは補償付き総和の誤差界，uは割り算の丸め)．
        # (1 + β)(1 + u) - 1のまま浮動小数点数で計算すると，1 + uが1に丸められて0になる．
        u = unit_roundoff(Float64)
        for (name, xs) in SUM_DATASETS
            β = u + gamma(length(xs) - 1, Float64)^2 * exact_condition_number(xs)
            exact = exact_sum(xs) / length(xs)
            @test relative_error(mean(xs), exact) <= β + u + β * u
        end
    end

    @testset "variance" begin
        @test variance([1.0, 2.0, 3.0, 4.0]) == 5 / 3
        @test variance([1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16]) == 30.0
        @test_throws ArgumentError variance([1.0])
        @test_throws ArgumentError variance(Float64[])
    end

    @testset "variance：厳密な性質 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:200)
        xs = shifted_normal_data(rng, n; center = 10.0^rand(rng, 0:8), spread = 10.0^rand(rng, -3:3))
        # 分散は負にならない．
        @test variance(xs) >= 0
        # 定数のデータの分散は厳密に0．
        @test variance(fill(xs[1], n)) == 0
        # 2の冪による拡大縮小は丸め誤差を生まないので，分散は厳密に4ᵏ倍になる．
        k = rand(rng, -30:30)
        @test variance(xs .* 2.0^k) == variance(xs) * 4.0^k
    end

    @testset "variance：誤差界 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:200)
        xs = shifted_normal_data(rng, n; center = 10.0^rand(rng, 0:8), spread = 10.0^rand(rng, -3:3))
        κ = exact_variance_condition_number(xs)
        @test relative_error(variance(xs), exact_variance(xs)) <= welford_tolerance(xs, κ)
    end

    @testset "variance：メタモルフィック関係 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:200)
        xs = integer_data(rng, n)
        exact = Float64(exact_variance(xs))
        tolerance(ys) = welford_tolerance(ys, exact_variance_condition_number(ys))
        # 平行移動：整数のデータに整数を足すのは厳密なので，正しい分散は変わらない．
        # 2つの計算結果の差は，それぞれの許容誤差の和で抑えられる．
        shifted = xs .+ 2.0^rand(rng, 10:40)
        @test abs(variance(shifted) - variance(xs)) <= (tolerance(shifted) + tolerance(xs)) * exact
        # 並べ替え：正しい分散は変わらない．
        permuted = shuffle(rng, xs)
        @test abs(variance(permuted) - variance(xs)) <= 2 * tolerance(xs) * exact
    end

    @testset "textbook_variance" begin
        @test textbook_variance([1.0, 2.0, 3.0, 4.0]) == 5 / 3
        @test_throws ArgumentError textbook_variance([1.0])
        # 平均が大きいデータでは，教科書の公式は負の分散を返すことがある．
        @test textbook_variance([1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16]) < 0
    end

    @testset "textbook_variance：誤差界 seed = $(seed)" for seed in SEEDS
        rng = Xoshiro(seed)
        n = rand(rng, 2:200)
        xs = shifted_normal_data(rng, n; center = 10.0^rand(rng, 0:4), spread = 10.0^rand(rng, -3:3))
        κ = exact_variance_condition_number(xs)
        # 誤差界(一次)：相対誤差 ≤ γ₃ₙ₊₁·κ² + γ₂．
        @test relative_error(textbook_variance(xs), exact_variance(xs)) <= gamma(3n + 1, Float64) * κ^2 + gamma(2, Float64)
    end

    @testset "variance_condition_number" begin
        # x = (1, -1)：‖x‖₂ = √2，S = 2なので条件数は1．
        @test variance_condition_number([1.0, -1.0]) == 1.0
        # x = (1, 2, 3)：‖x‖₂² = 14，S = 2なので条件数は√7．
        @test relative_error(variance_condition_number([1.0, 2.0, 3.0]), sqrt(big(7))) <= unit_roundoff(Float64)
        @test variance_condition_number([2.0, 2.0, 2.0]) == Inf
        @test_throws ArgumentError variance_condition_number([1.0])
    end
end
