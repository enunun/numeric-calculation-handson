using Random
using StableNumerics.ErrorBounds
using StableNumerics.ElementaryFunctions

@testset "ElementaryFunctions" begin
    @testset "reduce_argument" begin
        @test reduce_argument(0.0) == (0, 0.0)
        @test reduce_argument(0.25) == (0, 0.25)
        k, r = reduce_argument(1.0)
        @test k == 1
        # x = k·ln 2 + rの誤差：rの丸め(u|r|)，k·ln2_loの丸め，ln 2 = ln2_hi + ln2_loの表現誤差．
        u = unit_roundoff(Float64)
        representation = abs(log(big(2)) - big(ElementaryFunctions.LN2_HI) - big(ElementaryFunctions.LN2_LO))
        for x in (1.0, -1.0, 100.0, -500.0, 709.0, -745.0, log(2.0) / 2, 3 * log(2.0) / 2)
            k, r = reduce_argument(x)
            exact = big(x) - k * log(big(2))
            tolerance = u * abs(r) + u * abs(k * ElementaryFunctions.LN2_LO) + abs(k) * representation
            @test abs(big(r) - exact) <= tolerance
            # |r| ≤ (ln 2/2)(1 + 2⁻⁴⁰)：x/ln 2の丸めでkが半整数の近くで隣にずれる分を含む．
            @test abs(r) <= log(2.0) / 2 * (1 + 2.0^-40)
        end
    end

    @testset "exponential：特殊値と境界" begin
        @test exponential(0.0) == 1.0
        @test exponential(-0.0) == 1.0
        @test isnan(exponential(NaN))
        @test exponential(Inf) == Inf
        @test exponential(-Inf) == 0.0
        @test exponential(710.0) == Inf
        @test exponential(-746.0) == 0.0
        # 境界の近くの値：オーバーフローの直前，正規化数と非正規化数の境，0になる直前，還元の切り替わり．
        boundaries = [prevfloat(log(floatmax(Float64))), log(floatmin(Float64)), nextfloat(log(floatmin(Float64))),
                      -745.0, -744.4, 1e-300, -1e-300, 2.0^-30, log(2.0) / 2, prevfloat(log(2.0) / 2), nextfloat(log(2.0) / 2),
                      -log(2.0) / 2, 1.0, -1.0, 100.5, -100.5]
        for x in boundaries
            @test ulp_error(exponential(x), reference_exp(x)) <= exp_ulp_bound(x)
        end
    end

    @testset "exponential：標本検査 seed = $(seed)" for seed in 1:10
        rng = Xoshiro(seed)
        # 全範囲から一様に選ぶ点と，0の近くを細かく選ぶ点．
        xs = vcat(rand(rng, 500) .* (709.78 + 745.13) .- 745.13, randn(rng, 200) .* 10.0 .^ rand(rng, -20:0, 200))
        for x in xs
            @test ulp_error(exponential(x), reference_exp(x)) <= exp_ulp_bound(x)
        end
    end

    @testset "exponential：exp(x)·exp(-x) = 1 seed = $(seed)" for seed in 1:10
        rng = Xoshiro(seed)
        # 結果が正規化数の範囲で，それぞれの相対誤差はδ = 1.3 × 2u以下なので，積の相対誤差は2δ + δ²以下になる．
        δ = EXP_ULP_BOUND_NORMAL * 2 * unit_roundoff(Float64)
        for x in rand(rng, 200) .* 1400 .- 700
            @test abs(big(exponential(x)) * big(exponential(-x)) - 1) <= 2δ + δ^2
        end
    end

    @testset "exponential：差分テスト seed = $(seed)" for seed in 1:10
        rng = Xoshiro(seed)
        # Base.expの誤差を1 ULP未満と仮定する．2つの結果の差は(1.3 + 1) ULP以下になる．
        # 正しい値の属する区間の間隔は，Base.expの結果bの次の数の間隔eps(nextfloat(b))以下である．
        for x in rand(rng, 10_000) .* 1400 .- 700
            b = exp(x)
            @test abs(exponential(x) - b) <= (EXP_ULP_BOUND_NORMAL + 1) * eps(nextfloat(b))
        end
    end
end
