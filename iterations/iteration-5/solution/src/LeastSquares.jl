"""
    LeastSquares

ハウスホルダー変換によるQR分解と，最小二乗問題の解法．
"""
module LeastSquares

using LinearAlgebra: I, norm, triu
using ..Triangular: back_substitution
using ..LinearSolve: lu_factorize, solve

export QRFactorization, householder_qr, q_factor, lstsq_qr, lstsq_normal, polyfit

"""
    QRFactorization{T}

m × n行列AのQR分解A = QRの結果．`V`(m × n)のk列目はk番目のハウスホルダーベクトルvₖ(‖vₖ‖₂ = 1，k行目より上は0)で，
Qᵀ = Hₙ⋯H₁，Hₖ = I - 2vₖvₖᵀである．`R`はn × nの上三角行列である．
"""
struct QRFactorization{T<:AbstractFloat}
    V::Matrix{T}
    R::Matrix{T}
end

"""
    householder_qr(A)

m × n行列A(m ≥ n)のQR分解を，ハウスホルダー変換で求める．
k段目では，k列目のk行目より下の部分xを，ハウスホルダー変換で(-sign(x₁)‖x‖₂, 0, …, 0)に写す．
符号を-sign(x₁)にするのは，ベクトルvₖ = x - αe₁の計算で桁落ちを避けるためである．
m < nなら`ArgumentError`を投げる．
"""
function householder_qr(A::AbstractMatrix{T}) where {T<:AbstractFloat}
    m, n = size(A)
    m >= n || throw(ArgumentError("行数が列数より少ない行列はQR分解で扱わない(大きさ$(size(A)))"))
    R = Matrix{T}(A)
    V = zeros(T, m, n)
    for k in 1:n
        x = R[k:m, k]
        α = -copysign(norm(x), x[1])
        v = x
        v[1] -= α
        length_v = norm(v)
        # 列が0なら変換は要らない(Hₖ = I)．Rの対角が0になり，最小二乗問題は解けない．
        iszero(length_v) && continue
        v ./= length_v
        R[k:m, k:n] .-= 2 .* v .* (v' * R[k:m, k:n])
        V[k:m, k] = v
    end
    return QRFactorization(V, triu(R[1:n, :]))
end

# Qᵀb = Hₙ⋯H₁bを，ハウスホルダーベクトルを順に作用させて求める．
function apply_qt(F::QRFactorization{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    m, n = size(F.V)
    c = Vector{T}(b)
    for k in 1:n
        v = F.V[k:m, k]
        c[k:m] .-= 2 .* v .* (v' * c[k:m])
    end
    return c
end

"""
    q_factor(F)

QR分解Fの直交行列Qの最初のn列(m × n)を明示的に作って返す．
"""
function q_factor(F::QRFactorization{T}) where {T<:AbstractFloat}
    m, n = size(F.V)
    Q = Matrix{T}(I, m, n)
    for k in n:-1:1
        v = F.V[k:m, k]
        Q[k:m, :] .-= 2 .* v .* (v' * Q[k:m, :])
    end
    return Q
end

"""
    lstsq_qr(A, b)

最小二乗問題min‖Ax - b‖₂を，QR分解で解く．c = Qᵀbの最初のn成分について，Rx = cを後退代入で解く．
Aが列フルランクでなければ(Rの対角に0があれば)`SingularException`を投げる．
"""
function lstsq_qr(A::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    F = householder_qr(A)
    n = size(A, 2)
    return back_substitution(F.R, apply_qt(F, b)[1:n])
end

"""
    lstsq_normal(A, b)

最小二乗問題min‖Ax - b‖₂を，正規方程式AᵀAx = AᵀbをLU分解で解いて求める．比較のための関数である．
AᵀAの条件数はAの条件数の2乗になるので，前進誤差はκ₂(A)²に比例する．
"""
function lstsq_normal(A::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    size(A, 1) >= size(A, 2) || throw(ArgumentError("行数が列数より少ない(大きさ$(size(A)))"))
    return solve(lu_factorize(A' * A), A' * b)
end

"""
    polyfit(t, y, degree)

点(tᵢ, yᵢ)に，degree次の多項式c₀ + c₁t + ⋯ + c_degree·t^degreeを最小二乗で当てはめ，係数(c₀, …, c_degree)を返す．
ヴァンデルモンド行列Vᵢⱼ = tᵢ^(j - 1)について，`lstsq_qr(V, y)`で解く．
点の数がdegree + 1より少なければ`ArgumentError`を投げる．
"""
function polyfit(t::AbstractVector{T}, y::AbstractVector{T}, degree::Integer) where {T<:AbstractFloat}
    length(t) > degree || throw(ArgumentError("degree次の多項式にはdegree + 1個以上の点が必要である"))
    V = [ti^j for ti in t, j in 0:degree]
    return lstsq_qr(V, y)
end

end
