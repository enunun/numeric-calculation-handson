using StableNumerics.ErrorBounds

@testset "ErrorBounds" begin
    @testset "unit_roundoff" begin
        # 単位丸めは2の冪なので，==で厳密に比べられる．
        @test unit_roundoff(Float64) == 2.0^-53
        @test unit_roundoff(Float32) == 2.0f0^-24
    end

    @testset "gamma" begin
        u = unit_roundoff(Float64)
        # 有理数で厳密に求めたγₙと比べる．計算では1 - nuと割り算で2回丸めるので，相対誤差はγ₂以下になる．
        for n in [1, 10, 1000, 2^40]
            nu = n * Rational{BigInt}(u)
            @test relative_error(gamma(n, Float64), nu / (1 - nu)) <= gamma(2, Float64)
        end
        # γₙはnuより少し大きい．
        @test gamma(1000, Float64) > 1000u
        @test_throws ArgumentError gamma(2^53, Float64)
    end

    @testset "relative_error" begin
        @test relative_error(0.5, Rational{BigInt}(1 // 2)) == 0.0
        # |0.75 - 1/2|/(1/2) = 1/2は厳密に表せる．
        @test relative_error(0.75, Rational{BigInt}(1 // 2)) == 0.5
        @test relative_error(-0.75, Rational{BigInt}(-1 // 2)) == 0.5
        # 0.1は1/10を最も近い倍精度数に丸めた値なので，相対誤差は0より大きくu以下になる．
        @test 0 < relative_error(0.1, Rational{BigInt}(1 // 10)) <= unit_roundoff(Float64)
        @test relative_error(0.0, Rational{BigInt}(0)) == 0.0
        @test relative_error(1.0, Rational{BigInt}(0)) == Inf
    end

    @testset "relative_error(BigFloat)" begin
        @test relative_error(0.5, big(0.5)) == 0.0
        @test relative_error(0.75, big(0.5)) == 0.5
        @test relative_error(0.0, big(0.0)) == 0.0
        @test relative_error(1.0, big(0.0)) == Inf
        # 256ビットのBigFloatで求めた値と，有理数で厳密に求めた値は，
        # 最後にFloat64へ丸めるときの差(相対2u以下)しか違わない．
        exact = sqrt(big(2))
        @test relative_error(sqrt(2.0), exact) <= unit_roundoff(Float64)
        @test relative_error(0.1, big(1) / 10) ≈ relative_error(0.1, Rational{BigInt}(1 // 10)) rtol = 2 * unit_roundoff(Float64)
    end

    @testset "ulp_error" begin
        @test ulp_error(1.0, big(1.0)) == 0.0
        # 1.0の上の数の間隔は2⁻⁵²．正しい値が1のとき，nextfloat(1.0)の誤差は1 ULP．
        @test ulp_error(nextfloat(1.0), big(1.0)) == 1.0
        # ULPは正しい値の属する区間[2ᵉ, 2ᵉ⁺¹)の数の間隔で測る．prevfloat(1.0) = 1 - 2⁻⁵³は，1の間隔2⁻⁵²の半分だけずれている．
        @test ulp_error(prevfloat(1.0), big(1.0)) == 0.5
        @test ulp_error(1.0, big(1.0) - big(2.0)^-54) == 0.5
        # 非正規化数の間隔は2⁻¹⁰⁷⁴で一定である．
        @test ulp_error(nextfloat(0.0), big(0.0)) == 1.0
        @test ulp_error(3 * nextfloat(0.0), big(2.0)^-1074) == 2.0
        # 負の値は絶対値で測る．|-2 - 2⁻⁵¹|は[2, 4)にあり，間隔は2⁻⁵¹なので1 ULP．
        @test ulp_error(-2.0, big(-2.0) - big(2.0)^-51) == 1.0
    end
end
