using StableNumerics.ErrorBounds
using StableNumerics.Quadratic

@testset "Quadratic" begin
    @testset "discriminant" begin
        # b²と4acが厳密に表せれば，判別式も厳密に求まる．
        @test discriminant(1.0, -3.0, 2.0) == 1.0
        @test discriminant(1.0, 0.0, 1.0) == -4.0
        # 誤差界：相対誤差 ≤ γ₄(fmaで丸め誤差を取り戻すKahanの方法)．
        for (a, b, c) in QUADRATIC_CASES
            @test relative_error(discriminant(a, b, c), exact_discriminant(a, b, c)) <= gamma(4, Float64)
        end
    end

    @testset "quadratic_roots" begin
        @test quadratic_roots(1.0, -3.0, 2.0) == (1.0, 2.0)
        @test quadratic_roots(-1.0, 3.0, -2.0) == (1.0, 2.0)
        @test quadratic_roots(1.0, -2.0, 1.0) == (1.0, 1.0)
        @test quadratic_roots(1.0, 0.0, 0.0) == (0.0, 0.0)
        @test quadratic_roots(1.0, 0.0, 1.0) === nothing
        # 判別式は-4·2⁻⁵²で，わずかに負になる．
        @test quadratic_roots(1.0, -2.0, 1.0 + 2.0^-52) === nothing

        @test_throws ArgumentError quadratic_roots(0.0, 1.0, 1.0)
        for bad in (Inf, -Inf, NaN)
            @test_throws ArgumentError quadratic_roots(bad, 1.0, 1.0)
            @test_throws ArgumentError quadratic_roots(1.0, bad, 1.0)
            @test_throws ArgumentError quadratic_roots(1.0, 1.0, bad)
        end

        for (a, b, c) in QUADRATIC_CASES
            roots = quadratic_roots(a, b, c)
            reference = reference_roots(a, b, c)
            # 実根の有無が，厳密な判別式の符号と一致する．
            @test isnothing(roots) == isnothing(reference)
            isnothing(roots) && continue
            @test roots[1] <= roots[2]
            # 誤差界：各根の相対誤差 ≤ γ₆．
            @test relative_error(roots[1], reference[1]) <= gamma(6, Float64)
            @test relative_error(roots[2], reference[2]) <= gamma(6, Float64)
        end
    end

    @testset "参照解の精度" begin
        # 精度を256ビットから512ビットに上げても，参照解はu²より小さい相対差でしか変わらない．
        u = unit_roundoff(Float64)
        for (a, b, c) in QUADRATIC_CASES
            r256 = reference_roots(a, b, c; precision = 256)
            r512 = reference_roots(a, b, c; precision = 512)
            isnothing(r256) && continue
            for i in 1:2
                @test iszero(r512[i]) ? iszero(r256[i]) : abs(r256[i] - r512[i]) <= u^2 * abs(r512[i])
            end
        end
    end

    @testset "解と係数の関係" begin
        # 参照解を使わずに検査する性質．各根の相対誤差がγ₆以下なら，
        # 和の誤差は(γ₆/(1 - γ₆))(|r₁| + |r₂|)以下，積の相対誤差はγ₁₂以下になる．
        g6 = gamma(6, Float64)
        g12 = gamma(12, Float64)
        for (a, b, c) in QUADRATIC_CASES
            roots = quadratic_roots(a, b, c)
            isnothing(roots) && continue
            r1, r2 = big(roots[1]), big(roots[2])
            A, B, C = big(a), big(b), big(c)
            @test abs(r1 + r2 + B / A) <= g6 / (1 - g6) * (abs(r1) + abs(r2))
            @test abs(r1 * r2 - C / A) <= g12 * abs(C / A)
        end
    end

    @testset "root_backward_error" begin
        # 正確な根の後退誤差は0．
        @test root_backward_error(1.0, -3.0, 2.0, 1.0) == 0.0
        # p(1.5) = -0.25，|a|r² + |b||r| + |c| = 8.75なので，後退誤差は1/35．
        @test root_backward_error(1.0, -3.0, 2.0, 1.5) == Float64(1 // 35)
        # 誤差界：計算した根の後退誤差 ≤ γ₁₂(相対誤差γ₆以下の根から導く)．
        for (a, b, c) in QUADRATIC_CASES
            roots = quadratic_roots(a, b, c)
            isnothing(roots) && continue
            for r in roots
                @test root_backward_error(a, b, c, r) <= gamma(12, Float64)
            end
        end
    end

    @testset "root_condition_number" begin
        # x² - 3x + 2の根1と2では，どちらも(|a|r² + |b||r| + |c|)/|r·p′(r)| = 6．
        @test root_condition_number(1.0, -3.0, 2.0, 1.0) == 6.0
        @test root_condition_number(1.0, -3.0, 2.0, 2.0) == 6.0
        # 重根ではp′(r) = 0なので条件数は無限大，根が0なら相対誤差が定義できないので無限大．
        @test root_condition_number(1.0, -2.0, 1.0, 1.0) == Inf
        @test root_condition_number(2.0, 3.0, 0.0, 0.0) == Inf
        # 2つの根が近づくほど，条件数は大きくなる．
        κs = map((1e-4, 1e-7, 1e-10)) do δ
            a, b, c = 1.0, -(1.5 + 1.5 * (1 + δ)), 1.5 * (1.5 * (1 + δ))
            root_condition_number(a, b, c, quadratic_roots(a, b, c)[1])
        end
        @test κs[1] < κs[2] < κs[3]
    end
end
