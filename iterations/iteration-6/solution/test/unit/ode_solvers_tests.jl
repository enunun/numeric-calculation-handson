using StableNumerics.ODESolvers

@testset "ODESolvers" begin
    @testset "euler_step" begin
        # y + h·f(t, y)．どの計算も丸めない．
        @test euler_step((t, y) -> [1.0, t], 0.5, [1.0, 2.0], 0.5) == [1.5, 2.25]
    end

    @testset "rk4_step" begin
        # RK4は，右辺がtだけの3次以下の多項式なら厳密に積分する(シンプソンの公式)．
        @test rk4_step((t, y) -> [4t^3], 0.0, [0.0], 1.0) == [1.0]
        @test rk4_step((t, y) -> [3t^2 + 1], 0.0, [2.0], 2.0) == [12.0]
        # 4次の多項式では，シンプソンの公式の誤差が残る(y′ = 5t⁴，y(1) = 1)．
        @test rk4_step((t, y) -> [5t^4], 0.0, [0.0], 1.0) != [1.0]
    end

    @testset "integrate" begin
        f(t, y) = [y[2], -y[1]]
        @test integrate(rk4_step, f, 0.0, [1.0, 0.0], 0.1, 1) == rk4_step(f, 0.0, [1.0, 0.0], 0.1)
        @test integrate(euler_step, f, 0.0, [1.0, 0.0], 1.0, 4) ==
              euler_step(f, 0.75, euler_step(f, 0.5, euler_step(f, 0.25, euler_step(f, 0.0, [1.0, 0.0], 0.25), 0.25), 0.25), 0.25)
        @test_throws ArgumentError integrate(rk4_step, f, 0.0, [1.0, 0.0], 1.0, 0)
        # 要素の型によらずに動く．
        @test eltype(integrate(rk4_step, f, big(0.0), big.([1.0, 0.0]), big(1.0), 4)) == BigFloat
    end

    @testset "observed_order" begin
        @test observed_order(1.0, 0.5) == 1.0
        @test observed_order(16.0, 1.0) == 4.0
    end

    @testset "richardson_error_estimate" begin
        # 細かい解の誤差の推定は(粗い解 - 細かい解)/(2ᵖ - 1)．
        @test richardson_error_estimate([3.0], [1.0], 1) == [2.0]
        @test richardson_error_estimate([16.0, 1.0], [1.0, 16.0], 4) == [1.0, -1.0]
    end

    # 収束次数の検査は，BigFloatで同じ算法を実行して丸め誤差を取り除き，打ち切り誤差だけを測る．
    ns = [2^k for k in 3:9]
    @testset "収束次数：$(name)" for (name, step, p) in (("euler_step", euler_step, 1), ("rk4_step", rk4_step, 4))
        deviations = setprecision(BigFloat, 128) do
            order_deviations(ode_errors(step, BigFloat, ns), p)
        end
        # 観測次数は理論次数に近づき，そのずれは刻み幅を半分にするごとにほぼ半分になる．
        for i in 1:length(deviations)-1
            @test deviations[i+1] <= ORDER_DEVIATION_RATIO * deviations[i]
        end
    end

    @testset "Float64の丸め誤差は打ち切り誤差に比べて小さい：$(name)" for (name, step) in (("euler_step", euler_step), ("rk4_step", rk4_step))
        # 丸め誤差の寄与が打ち切り誤差の1%以下なら，観測次数への影響は|log₂(1 ± 0.01)| ≈ 0.015以下である．
        for n in ns
            y64 = integrate(step, manufactured_rhs, 0.0, manufactured_solution(0.0), 2.0, n)
            ybig, truncation = setprecision(BigFloat, 128) do
                y = integrate(step, manufactured_rhs, big(0.0), manufactured_solution(big(0.0)), big(2.0), n)
                y, maximum(abs, y - manufactured_solution(big(2.0)))
            end
            @test maximum(abs, big.(y64) - ybig) <= truncation / 100
        end
    end

    @testset "リチャードソン外挿の推定は真の誤差に近づく" begin
        deviations = setprecision(BigFloat, 128) do
            t_end = big(2.0)
            y0 = manufactured_solution(big(0.0))
            solutions = [integrate(rk4_step, manufactured_rhs, big(0.0), y0, t_end, n) for n in ns]
            map(1:length(ns)-1) do i
                estimate = richardson_error_estimate(solutions[i], solutions[i+1], 4)
                actual = solutions[i+1] - manufactured_solution(t_end)
                maximum(abs, estimate - actual) / maximum(abs, actual)
            end
        end
        # 推定の相対誤差も，刻み幅を半分にするごとにほぼ半分になる．
        for i in 1:length(deviations)-1
            @test deviations[i+1] <= ORDER_DEVIATION_RATIO * deviations[i]
        end
    end
end
