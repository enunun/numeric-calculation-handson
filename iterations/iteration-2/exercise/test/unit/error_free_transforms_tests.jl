using StableNumerics.ErrorFreeTransforms

@testset "ErrorFreeTransforms" begin
    @testset "two_sum" begin
        # 丸めが起きなければ，誤差の項は0になる．
        @test two_sum(1.0, 2.0) == (3.0, 0.0)
        # 1e16 + 1は倍精度で表せないので，丸めで失われた1が誤差の項に残る．
        @test two_sum(1e16, 1.0) == (1e16, 1.0)

        for (a, b) in EFT_PAIRS
            s, e = two_sum(a, b)
            # sは普通の浮動小数点数の和に等しい．
            @test s == a + b
            # 無誤差変換：a + b = s + eが有理数の演算で厳密に成り立つ．
            @test Rational{BigInt}(a) + Rational{BigInt}(b) == Rational{BigInt}(s) + Rational{BigInt}(e)
        end
    end

    @testset "two_prod" begin
        # 積が厳密に表せれば，誤差の項は0になる．
        @test two_prod(3.0, 0.5) == (1.5, 0.0)
        @test two_prod(0.1, 0.1) == (0.1 * 0.1, -8.326672684688674e-19)

        for (a, b) in EFT_PAIRS
            p, e = two_prod(a, b)
            @test p == a * b
            # 無誤差変換：a × b = p + eが有理数の演算で厳密に成り立つ．
            @test Rational{BigInt}(a) * Rational{BigInt}(b) == Rational{BigInt}(p) + Rational{BigInt}(e)
        end
    end
end
