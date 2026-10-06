# 公開APIだけを使い，条件数から誤差の上界を見積もり，実際の誤差がその中に収まることを確かめる．

@testset "総和の精度の見積もり" begin
    u = unit_roundoff(Float64)
    for (name, xs) in SUM_DATASETS
        n = length(xs)
        κ = sum_condition_number(xs)
        exact = exact_sum(xs)
        # 計算したκの相対誤差は，γₙ₋₁をγₙに替えた余裕(相対1/n程度)よりずっと小さい．
        @test relative_error(naive_sum(xs), exact) <= gamma(n, Float64) * κ
        @test relative_error(compensated_sum(xs), exact) <= u + gamma(n, Float64)^2 * κ
    end
end
