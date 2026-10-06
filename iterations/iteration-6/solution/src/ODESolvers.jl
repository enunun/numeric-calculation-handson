"""
    ODESolvers

常微分方程式の初期値問題y′ = f(t, y)，y(t₀) = y₀の数値解法と，収束次数の検証に使う関数．
yはベクトルで，要素の型(`Float64`，`BigFloat`など)によらずに動く．
"""
module ODESolvers

export euler_step, rk4_step, integrate, observed_order, richardson_error_estimate

"""
    euler_step(f, t, y, h)

Euler法の1ステップy + h·f(t, y)を返す．局所打ち切り誤差はO(h²)，大域誤差はO(h)である(1次の方法)．
"""
euler_step(f, t, y, h) = y + h * f(t, y)

"""
    rk4_step(f, t, y, h)

古典的な4次のルンゲ＝クッタ法の1ステップを返す．局所打ち切り誤差はO(h⁵)，大域誤差はO(h⁴)である．
右辺がtだけの3次以下の多項式なら，シンプソンの公式と同じく厳密に積分する．
"""
function rk4_step(f, t, y, h)
    k1 = f(t, y)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + h / 2, y + h / 2 * k2)
    k4 = f(t + h, y + h * k3)
    return y + h / 6 * (k1 + 2k2 + 2k3 + k4)
end

"""
    integrate(step, f, t0, y0, t_end, n)

区間[t0, t_end]をn等分し，1ステップの方法`step`(`euler_step`，`rk4_step`など)をn回適用して，t_endでの近似解を返す．
k番目の時刻はt0 + k·hで計算する．hを足し続けると，時刻に丸め誤差がたまるからである．
n < 1なら`ArgumentError`を投げる．
"""
function integrate(step, f, t0, y0, t_end, n::Integer)
    n >= 1 || throw(ArgumentError("分割数nは1以上でなければならない(n = $(n))"))
    h = (t_end - t0) / n
    y = y0
    for k in 0:n-1
        y = step(f, t0 + k * h, y, h)
    end
    return y
end

"""
    observed_order(error_coarse, error_fine)

刻み幅をhとh/2にしたときの誤差から，観測次数log₂(error_coarse/error_fine)を返す．
大域誤差がChᵖ(1 + Dh + ⋯)と展開できるとき，観測次数はp + O(h)である．
"""
observed_order(error_coarse, error_fine) = log2(error_coarse / error_fine)

"""
    richardson_error_estimate(y_coarse, y_fine, p)

p次の方法で刻み幅をhとh/2にした解から，細かい解y_fineの誤差を(y_coarse - y_fine)/(2ᵖ - 1)と推定する(リチャードソン外挿)．
推定の相対誤差はO(h)である．
"""
richardson_error_estimate(y_coarse, y_fine, p::Integer) = (y_coarse - y_fine) / (2^p - 1)

end
