"""
    Hamiltonian

ハミルトン系q″ = F(q)(F(q) = -∇V(q)，p = q′)を，シンプレクティック法(Störmer–Verlet法)で解く関数．
qとpはベクトルで，要素の型(`Float64`，`BigFloat`，`Rational`など)によらずに動く．
"""
module Hamiltonian

export verlet_step, verlet_integrate

"""
    verlet_step(force, q, p, h)

Störmer–Verlet法の1ステップを行い，`(q_new, p_new)`を返す．`force(q)`は力F(q)を返す関数である．

    p_half = p + h/2·F(q)
    q_new  = q + h·p_half
    p_new  = p_half + h/2·F(q_new)

2次の方法で，シンプレクティック写像である．hを-hに変えると，1ステップ前の状態に戻る(時間の反転に対して対称)．
Fが中心力(F(q)がqに平行)なら，角運動量を厳密に保つ．
"""
function verlet_step(force, q, p, h)
    p_half = p + h / 2 * force(q)
    q_new = q + h * p_half
    p_new = p_half + h / 2 * force(q_new)
    return (q_new, p_new)
end

"""
    verlet_integrate(force, q0, p0, h, n)

`verlet_step`を刻み幅hでn回適用し，`(q, p)`を返す．n = 0なら`(q0, p0)`を返す．
n < 0なら`ArgumentError`を投げる．
"""
function verlet_integrate(force, q0, p0, h, n::Integer)
    n >= 0 || throw(ArgumentError("ステップ数nは0以上でなければならない(n = $(n))"))
    q, p = q0, p0
    for _ in 1:n
        q, p = verlet_step(force, q, p, h)
    end
    return (q, p)
end

end
