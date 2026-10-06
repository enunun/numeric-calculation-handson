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
end
