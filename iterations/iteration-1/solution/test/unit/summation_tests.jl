using StableNumerics.ErrorBounds
using StableNumerics.Summation

@testset "Summation" begin
    @testset "naive_sum" begin
        @test naive_sum(Float64[]) == 0.0
        # 整数の和は丸めずに表せるので，厳密に一致する．
        @test naive_sum([1.0, 2.0, 3.0]) == 6.0
        # 1e16 + 1.0の丸めで1.0が失われる(情報落ち)．
        @test naive_sum([1e16, 1.0, -1e16]) == 0.0

        # 誤差界：相対誤差 ≤ γₙ₋₁·κ．
        for (name, xs) in SUM_DATASETS
            bound = gamma(length(xs) - 1, Float64) * exact_condition_number(xs)
            @test relative_error(naive_sum(xs), exact_sum(xs)) <= bound
        end
    end

    @testset "compensated_sum" begin
        @test compensated_sum(Float64[]) == 0.0
        @test compensated_sum([1e16, 1.0, -1e16]) == 1.0
        # 0.1を10個足した厳密な和を，最も近い倍精度数に丸めた値が得られる．
        @test compensated_sum(fill(0.1, 10)) == Float64(exact_sum(fill(0.1, 10)))

        # 誤差界：相対誤差 ≤ u + γₙ₋₁²·κ．
        u = unit_roundoff(Float64)
        for (name, xs) in SUM_DATASETS
            bound = u + gamma(length(xs) - 1, Float64)^2 * exact_condition_number(xs)
            @test relative_error(compensated_sum(xs), exact_sum(xs)) <= bound
        end
    end

    @testset "sum_condition_number" begin
        # 符号がそろっていれば打ち消しは起きず，条件数は1になる．
        @test sum_condition_number([1.0, 2.0, 3.0]) == 1.0
        @test sum_condition_number([1e16, 1.0, -1e16]) == 2e16
        @test sum_condition_number([1.0, -1.0]) == Inf
        # 分子(素朴な総和，相対誤差γₙ₋₁以下)，分母(補償付き総和，相対誤差β以下)，
        # 割り算(相対誤差u以下)，参照解をFloat64へ丸める誤差(u以下)を積み上げて許容誤差にする．
        u = unit_roundoff(Float64)
        for (name, xs) in SUM_DATASETS
            g = gamma(length(xs) - 1, Float64)
            κ = exact_condition_number(xs)
            β = u + g^2 * κ
            tolerance = (1 + g) * (1 + u) / (1 - β) - 1 + u
            @test sum_condition_number(xs) ≈ κ rtol = tolerance
        end
    end
end
