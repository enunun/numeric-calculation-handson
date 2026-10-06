# 公開APIだけで多項式を当てはめ，QR分解と正規方程式の精度を，条件数から見積もった許容誤差と比べる．

@testset "最小二乗法の解き方の比較" begin
    t = collect(range(0, 1; length = 50))
    V = [ti^j for ti in t, j in 0:9]
    y = V * ones(10)
    exact = exact_least_squares(V, y)
    residual = Float64.(Rational{BigInt}.(y) - Rational{BigInt}.(V) * exact)
    tolerance = least_squares_tolerance(V, Float64.(exact), residual)
    # polyfitはQR分解で解くので，前進誤差はγ₂ₘₙ(κ₂ + κ₂²ρ)以下になる．
    @test relative_error_2norm(polyfit(t, y, 9), exact) <= tolerance
    @test polyfit(t, y, 9) == lstsq_qr(V, y)
    # 正規方程式は条件数を2乗するので(κ₂ ≈ 3.6 × 10⁶)，同じ許容誤差に収まらない．
    @test relative_error_2norm(lstsq_normal(V, y), exact) > tolerance
end
