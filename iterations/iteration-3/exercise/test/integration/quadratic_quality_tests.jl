# 公開APIだけを使い，求めた根の品質を後退誤差と条件数で評価する．

@testset "二次方程式の根の品質" begin
    u = unit_roundoff(Float64)
    # 参照解を使わずに確かめられること：計算したすべての根の後退誤差は誤差仕様書の上界γ₁₂以下である．
    for (a, b, c) in QUADRATIC_CASES
        roots = quadratic_roots(a, b, c)
        isnothing(roots) && continue
        @test root_backward_error(a, b, c, roots[1]) <= gamma(12, Float64)
        @test root_backward_error(a, b, c, roots[2]) <= gamma(12, Float64)
    end

    # Kahanの例では，条件数から見積もった前進誤差κuはγ₆より大きい．
    # 判別式を正確に計算するので，実際の相対誤差はγ₆以下に収まる．
    a, b, c = 94906265.625, -189812534.0, 94906268.375
    roots = quadratic_roots(a, b, c)
    reference = reference_roots(a, b, c)
    for i in 1:2
        @test root_condition_number(a, b, c, roots[i]) * u > gamma(6, Float64)
        @test relative_error(roots[i], reference[i]) <= gamma(6, Float64)
    end
end
