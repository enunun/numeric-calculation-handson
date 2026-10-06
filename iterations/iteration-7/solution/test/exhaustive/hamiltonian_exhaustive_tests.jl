# Störmer–Verlet法で調和振動子を10⁶ステップ解き，すべてのステップで保存量の誤差を検査する．
# 保存量はBigFloatで評価するので，評価の丸め誤差は入らない．許容誤差の導き方はdesign/error-spec.mdにある．
@testset "Störmer–Verlet法の長時間の保存量" begin
    h, n = 0.1, 10^6
    hb = big(h)

    @testset "1自由度：修正エネルギーとエネルギー" begin
        q, p = [1.0], [0.0]
        modified0 = modified_energy(big.(q), big.(p), hb)
        max_modified_drift = big(0.0)
        max_energy_error = big(0.0)
        for _ in 1:n
            q, p = verlet_step(harmonic_force, q, p, h)
            qb, pb = big.(q), big.(p)
            max_modified_drift = max(max_modified_drift, abs(modified_energy(qb, pb, hb) - modified0))
            max_energy_error = max(max_energy_error, abs(energy(qb, pb) - big(1) / 2))
        end
        rounding = gamma(VERLET_MODIFIED_ENERGY_ROUNDING * n, Float64)
        @test max_modified_drift <= rounding
        @test max_energy_error <= hb^2 / 8 + 2rounding
    end

    @testset "2自由度の円軌道：角運動量" begin
        q, p = [1.0, 0.0], [0.0, 1.0]
        max_drift = big(0.0)
        for _ in 1:n
            q, p = verlet_step(harmonic_force, q, p, h)
            max_drift = max(max_drift, abs(angular_momentum(big.(q), big.(p)) - 1))
        end
        @test max_drift <= gamma(VERLET_ANGULAR_MOMENTUM_ROUNDING * n, Float64)
    end
end
