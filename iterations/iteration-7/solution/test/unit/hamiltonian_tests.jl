using StableNumerics.Hamiltonian

@testset "Hamiltonian" begin
    @testset "verlet_step" begin
        # 調和振動子をh = 1/2で1ステップ進める．どの計算も丸めない．
        @test verlet_step(harmonic_force, [1.0], [0.0], 0.5) == ([0.875], [-0.46875])
        # 力が0なら等速直線運動になる．
        @test verlet_step(q -> zero(q), [1.0, 2.0], [0.5, -0.25], 2.0) == ([2.0, 1.5], [0.5, -0.25])
        # hを-hに変えると，1ステップ前の状態に戻る．
        @test verlet_step(harmonic_force, [0.875], [-0.46875], -0.5) == ([1.0], [0.0])
    end

    @testset "verlet_integrate" begin
        @test verlet_integrate(harmonic_force, [1.0], [0.0], 0.5, 0) == ([1.0], [0.0])
        q1, p1 = verlet_step(harmonic_force, [1.0], [0.0], 0.5)
        @test verlet_integrate(harmonic_force, [1.0], [0.0], 0.5, 2) == verlet_step(harmonic_force, q1, p1, 0.5)
        @test_throws ArgumentError verlet_integrate(harmonic_force, [1.0], [0.0], 0.5, -1)
    end

    # 有理数(Rational{BigInt})で計算すると丸め誤差がないので，厳密に保たれるはずの量を==で検査できる．
    @testset "厳密に保たれる量(有理数)" begin
        h = big(1) // 10
        q0, p0 = [big(1) // 1], [big(0) // 1]
        q, p = verlet_integrate(harmonic_force, q0, p0, h, 20)
        @test modified_energy(q, p, h) == modified_energy(q0, p0, h)
        # エネルギーそのものは保たれない．
        @test energy(q, p) != energy(q0, p0)
        # 中心力(F(q) = -|q|²q)なら角運動量が保たれ，時間を反転すると元に戻る．
        central_force(q) = -sum(abs2, q) * q
        q0, p0 = [big(1) // 1, big(0) // 1], [big(0) // 1, big(1) // 2]
        q, p = verlet_integrate(central_force, q0, p0, h, 4)
        @test angular_momentum(q, p) == angular_momentum(q0, p0)
        @test verlet_integrate(central_force, q, p, -h, 4) == (q0, p0)
    end

    @testset "RK4は調和振動子のエネルギーを|R(ih)|²倍ずつ減らす(有理数)" begin
        # RK4を調和振動子に1ステップ適用すると，複素数q - ipにR(ih) = 1 + ih - h²/2 - ih³/6 + h⁴/24を掛けることになる．
        h = big(1) // 10
        decay = (1 - h^2 / 2 + h^4 / 24)^2 + (h - h^3 / 6)^2
        @test decay < 1
        y = integrate(rk4_step, (t, y) -> [y[2], -y[1]], big(0) // 1, [big(1) // 1, big(0) // 1], 10h, 10)
        @test energy(y[1:1], y[2:2]) == decay^10 * energy([big(1) // 1], [big(0) // 1])
    end

    @testset "Störmer–Verlet法は2次の方法である" begin
        # 調和振動子の厳密解q = cos t，p = -sin tとの誤差を，BigFloatで測る．
        ns = [2^k for k in 3:9]
        deviations = setprecision(BigFloat, 128) do
            t_end = big(2.0)
            errors = map(ns) do n
                q, p = verlet_integrate(harmonic_force, [big(1.0)], [big(0.0)], t_end / n, n)
                max(abs(q[1] - cos(t_end)), abs(p[1] + sin(t_end)))
            end
            order_deviations(errors, 2)
        end
        for i in 1:length(deviations)-1
            @test deviations[i+1] <= ORDER_DEVIATION_RATIO * deviations[i]
        end
    end

    @testset "Float64での保存量の誤差(10⁴ステップ)" begin
        h, n = 0.1, 10^4
        # 1自由度：修正エネルギーは丸め誤差の分しか変わらず，エネルギーの誤差はh²/8以下にとどまる．
        q, p = verlet_integrate(harmonic_force, [1.0], [0.0], h, n)
        modified_drift = abs(modified_energy(big.(q), big.(p), big(h)) - modified_energy([big(1.0)], [big(0.0)], big(h)))
        rounding = gamma(VERLET_MODIFIED_ENERGY_ROUNDING * n, Float64)
        @test modified_drift <= rounding
        @test abs(energy(big.(q), big.(p)) - big(1) / 2) <= big(h)^2 / 8 + 2rounding
        # 2自由度の円軌道：角運動量は丸め誤差の分しか変わらない．
        q, p = verlet_integrate(harmonic_force, [1.0, 0.0], [0.0, 1.0], h, n)
        @test abs(angular_momentum(big.(q), big.(p)) - 1) <= gamma(VERLET_ANGULAR_MOMENTUM_ROUNDING * n, Float64)
    end
end
