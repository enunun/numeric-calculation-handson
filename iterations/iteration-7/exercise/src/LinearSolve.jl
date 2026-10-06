"""
    LinearSolve

LU分解による連立1次方程式の解法と，解の後退誤差・分解の増大因子．
"""
module LinearSolve

using LinearAlgebra: SingularException
using ..Triangular: forward_substitution, back_substitution

export LUFactorization, lu_factorize, solve, backward_error, growth_factor

"""
    LUFactorization{T}

LU分解PA = LUの結果．`LU`の狭義下三角部分にLの対角より下の要素を，上三角部分にUを格納する(Lの対角は1)．
`perm`は行の並べ替えを表し，PAのi行目はAの`perm[i]`行目である．
"""
struct LUFactorization{T<:AbstractFloat}
    LU::Matrix{T}
    perm::Vector{Int}
end

"""
    lu_factorize(A; pivot = true)

正方行列AのLU分解を，ガウスの消去法で求める．
`pivot = true`(既定)では，各段で列の絶対値が最大の要素を持つ行をピボットに選ぶ(部分ピボット選択)．
計算したL̂，Ûは|PA - L̂Û| ≤ γₙ|L̂||Û|を満たす．
ピボットが0になったら`SingularException`を，Aが正方でなければ`DimensionMismatch`を投げる．
"""
function lu_factorize(A::AbstractMatrix{T}; pivot::Bool = true) where {T<:AbstractFloat}
    n = size(A, 1)
    size(A, 2) == n || throw(DimensionMismatch("LU分解には正方行列が必要である(大きさ$(size(A)))"))
    LU = Matrix{T}(A)
    perm = collect(1:n)
    for k in 1:n
        if pivot
            p = k - 1 + argmax(abs.(LU[k:n, k]))
            if p != k
                LU[[k, p], :] = LU[[p, k], :]
                perm[[k, p]] = perm[[p, k]]
            end
        end
        iszero(LU[k, k]) && throw(SingularException(k))
        for i in k+1:n
            LU[i, k] /= LU[k, k]
            for j in k+1:n
                LU[i, j] -= LU[i, k] * LU[k, j]
            end
        end
    end
    return LUFactorization(LU, perm)
end

"""
    solve(F, b)

LU分解Fを使ってAx = bを解く．前進代入でLy = Pbを，後退代入でUx = yを解く．
計算した解x̂は(A + ΔA)x̂ = b，|ΔA| ≤ γ₃ₙPᵀ|L̂||Û|を満たす．
"""
function solve(F::LUFactorization{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    n = length(F.perm)
    length(b) == n || throw(DimensionMismatch("bの長さ$(length(b))が行列の大きさ$(n)と合わない"))
    # F.LUの狭義下三角部分がL(対角は1)，上三角部分がUである．
    y = forward_substitution(F.LU, b[F.perm]; unit_diagonal = true)
    return back_substitution(F.LU, y)
end

"""
    backward_error(A, x, b)

xの(∞ノルムによる)後退誤差‖b - Ax‖∞/(‖A‖∞‖x‖∞ + ‖b‖∞)を返す(Rigal–Gaches)．
これは，(A + ΔA)x = b + Δb，‖ΔA‖∞ ≤ η‖A‖∞，‖Δb‖∞ ≤ η‖b‖∞を満たす最小のηである．
残差とノルムは有理数で厳密に計算し，結果を`Float64`へ丸める．
"""
function backward_error(A::AbstractMatrix{T}, x::AbstractVector{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    Q, y, c = Rational{BigInt}.(A), Rational{BigInt}.(x), Rational{BigInt}.(b)
    residual = maximum(abs, c - Q * y)
    scale = maximum(sum(abs, Q; dims = 2)) * maximum(abs, y) + maximum(abs, c)
    iszero(scale) && return 0.0
    return Float64(residual / scale)
end

"""
    growth_factor(F, A)

LU分解の増大因子maxᵢⱼ|uᵢⱼ|/maxᵢⱼ|aᵢⱼ|を返す．
部分ピボット選択では2ⁿ⁻¹以下だが，ピボット選択なしでは際限なく大きくなりうる．
"""
function growth_factor(F::LUFactorization{T}, A::AbstractMatrix{T}) where {T<:AbstractFloat}
    n = size(A, 1)
    largest = maximum(abs(F.LU[i, j]) for i in 1:n for j in i:n)
    return largest / maximum(abs, A)
end

end
