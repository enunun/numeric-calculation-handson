# 公開APIだけを使い，ピボット選択の有無で解の品質がどう変わるかを，増大因子と後退誤差で確かめる．

@testset "ピボット選択と後退誤差 seed = $(seed)" for seed in SEEDS
    rng = Xoshiro(seed)
    n = rand(rng, 3:12)
    # 条件数の小さい行列の(1, 1)要素だけを小さくする．問題の条件はほとんど悪くならない．
    A = matrix_with_condition(rng, n, 10.0)
    A[1, 1] *= 1e-12
    b = A * randn(rng, n)
    pivoted = lu_factorize(A)
    unpivoted = lu_factorize(A; pivot = false)
    # 増大因子ρから，後退誤差の上界γ₃ₙn²ρが公開APIだけで見積もれる．
    bound = gamma(3n, Float64) * n^2 * growth_factor(pivoted, A)
    @test backward_error(A, solve(pivoted, b), b) <= bound
    # ピボット選択なしでは増大因子が大きくなり，後退誤差はピボット選択ありの上界を超える．
    @test growth_factor(unpivoted, A) > growth_factor(pivoted, A)
    @test backward_error(A, solve(unpivoted, b), b) > bound
end
