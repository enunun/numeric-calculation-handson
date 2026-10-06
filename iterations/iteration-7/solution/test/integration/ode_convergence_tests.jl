# 公開APIだけを使い，厳密解のわからない問題(振り子)で収束次数を確かめる．
# p次の方法では，刻み幅h，h/2の解の差y_h - y_{h/2}もChᵖ(1 - 2⁻ᵖ)のように振る舞うので，
# 隣り合う差の比から，厳密解を使わずに観測次数が求まる．

# 判定基準は漸近展開に基づくので，hが十分小さい範囲(漸近範囲)でだけ使える．
# Euler法では，n = 2⁷までは観測次数のずれが一度0に近づいてから増え，半分ずつにはならない．
@testset "厳密解を使わない収束次数の検査：$(name)" for (name, step, p, ks) in (("euler_step", euler_step, 1, 8:13), ("rk4_step", rk4_step, 4, 4:9))
    pendulum(t, y) = [y[2], -sin(y[1])]
    ns = [2^k for k in ks]
    solutions = [integrate(step, pendulum, 0.0, [1.0, 0.0], 5.0, n) for n in ns]
    differences = [maximum(abs, solutions[i] - solutions[i+1]) for i in 1:length(ns)-1]
    deviations = [abs(observed_order(differences[i], differences[i+1]) - p) for i in 1:length(differences)-1]
    for i in 1:length(deviations)-1
        @test deviations[i+1] <= ORDER_DEVIATION_RATIO * deviations[i]
    end
end
