"""
    ODESolvers

常微分方程式の初期値問題y′ = f(t, y)，y(t₀) = y₀の数値解法と，収束次数の検証に使う関数．
yはベクトルで，要素の型(`Float64`，`BigFloat`など)によらずに動く．
"""
module ODESolvers

export euler_step, rk4_step, integrate, observed_order, richardson_error_estimate
export bs32_step, integrate_adaptive

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


"""
    bs32_step(f, t, y, h)

Bogacki–Shampineの埋め込みルンゲ＝クッタ法の1ステップを行い，`(y_new, error_estimate)`を返す．
`y_new`は3次の解(局所打ち切り誤差O(h⁴))である．
`error_estimate`は3次の解と2次の解の差で，2次の解の局所誤差O(h³)を推定する．
右辺がtだけの2次以下の多項式なら3次の解は厳密で，1次以下なら推定は0になる．
"""
function bs32_step(f, t, y, h)
    k1 = f(t, y)
    k2 = f(t + h / 2, y + h / 2 * k1)
    k3 = f(t + 3h / 4, y + 3h / 4 * k2)
    y_new = y + h / 9 * (2k1 + 3k2 + 4k3)
    k4 = f(t + h, y_new)
    # 2次の解はy + h(7k₁ + 6k₂ + 8k₃ + 3k₄)/24．3次の解との差を，引き算せずに係数から直接求める．
    error_estimate = h / 72 * (-5k1 + 6k2 + 8k3 - 9k4)
    return (y_new, error_estimate)
end

"""
    integrate_adaptive(f, t0, y0, t_end; rtol, atol)

`bs32_step`の局所誤差の推定から刻み幅を自動で調整し，t_endでの近似解を求める．
`(y = 近似解, accepted = 受理したステップ数, rejected = 棄却したステップ数)`を返す．

各成分の目標をatol + rtol·max(|yᵢ|, |y_newᵢ|)とし，推定を目標で割った値の二乗平均平方根errが1以下ならステップを受理する．
次の刻み幅は，hに0.9·err^(-1/3)を掛けて求める．ただし，掛ける値は1/5以上5以下に制限する．
最初の刻み幅は(t_end - t0)/100とする．
rtolとatolは1ステップの局所誤差の目標で，t_endでの大域誤差の上界ではない．

rtol ≤ 0，atol ≤ 0，t_end ≤ t0なら`ArgumentError`を投げる．
刻み幅がtに対して小さくなりすぎて時刻が進まなくなったら，`ErrorException`を投げる．
"""
function integrate_adaptive(f, t0, y0, t_end; rtol, atol)
    rtol > 0 || throw(ArgumentError("rtolは正でなければならない(rtol = $(rtol))"))
    atol > 0 || throw(ArgumentError("atolは正でなければならない(atol = $(atol))"))
    t_end > t0 || throw(ArgumentError("t_endはt0より大きくなければならない(t0 = $(t0)，t_end = $(t_end))"))
    t = t0
    y = y0
    h = (t_end - t0) / 100
    accepted = 0
    rejected = 0
    while t < t_end
        last_step = h >= t_end - t
        if last_step
            h = t_end - t
        end
        t + h > t || error("刻み幅が小さくなりすぎた(t = $(t)，h = $(h))")
        y_new, error_estimate = bs32_step(f, t, y, h)
        scale = atol .+ rtol .* max.(abs.(y), abs.(y_new))
        err = sqrt(sum(abs2, error_estimate ./ scale) / length(y))
        if err <= 1
            # 最後のステップでは，t + hの丸めでt_endを越えたり届かなかったりしないように，t_endを代入する．
            t = last_step ? t_end : t + h
            y = y_new
            accepted += 1
        else
            rejected += 1
        end
        # err = 0なら倍率は上限の5になる．errがInfやNaN(解が発散した)なら，下限の1/5で刻み幅を小さくする．
        factor = isfinite(err) ? clamp(9 * cbrt(1 / err) / 10, 1 / 5, 5) : 1 / 5
        h *= factor
    end
    return (y = y, accepted = accepted, rejected = rejected)
end

end
