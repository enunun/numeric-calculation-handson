# 公開APIだけを使い，厳密解のわからないケプラー問題で，Störmer–Verlet法がエネルギーを保つことを確かめる．
# シンプレクティック法のエネルギーの誤差は有界で，時間に比例してたまらない．
# 1周期と10周期で誤差の最大値を比べ，比が有界の場合(1)とたまる場合(10)の幾何平均√10以下であることを検査する．
@testset "ケプラー問題のエネルギーの誤差はたまらない" begin
    kepler_force(q) = -q / sqrt(sum(abs2, q))^3
    kepler_energy(q, p) = sum(abs2, p) / 2 - 1 / sqrt(sum(abs2, q))
    # 離心率0.44の楕円軌道．周期は約15である．
    q0, p0 = [1.0, 0.0], [0.0, 1.2]
    h, n_period = 0.05, 300
    e0 = kepler_energy(q0, p0)
    max_errors = map((n_period, 10n_period)) do n
        q, p = q0, p0
        max_error = 0.0
        for _ in 1:n
            q, p = verlet_step(kepler_force, q, p, h)
            max_error = max(max_error, abs(kepler_energy(q, p) - e0))
        end
        max_error
    end
    @test max_errors[2] <= BOUNDED_GROWTH_RATIO * max_errors[1]
end
