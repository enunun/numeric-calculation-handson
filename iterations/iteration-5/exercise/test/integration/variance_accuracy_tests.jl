# 公開APIだけを使い，分散の条件数から2つの方法の誤差の上界を見積もり，方法を選ぶ筋書きをたどる．

@testset "分散の方法の選択 seed = $(seed)" for seed in SEEDS
    rng = Xoshiro(seed)
    n = rand(rng, 2:200)
    xs = shifted_normal_data(rng, n; center = 1e8, spread = 1.0)
    κ = variance_condition_number(xs)
    # 平均が標準偏差の10⁸倍のデータでは，教科書の公式の誤差の上界は1を超え，正しい桁が保証されない．
    @test gamma(3n + 1, Float64) * κ^2 > 1
    # Welfordの算法の誤差の上界は1より小さく，実際の誤差もその中に収まる．
    bound = gamma(2n, Float64) * κ
    @test bound < 1
    @test relative_error(variance(xs), exact_variance(xs)) <= bound
    # データはすべて正なので，総和の条件数は1である．平均の相対誤差はβ + u + βu(β = u + γₙ₋₁²)以下になる．
    u = unit_roundoff(Float64)
    β = u + gamma(n - 1, Float64)^2
    @test relative_error(mean(xs), exact_sum(xs) / n) <= β + u + β * u
end
