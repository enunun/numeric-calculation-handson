"""
    Triangular

三角行列を係数とする連立1次方程式の解法(前進代入と後退代入)．
"""
module Triangular

using LinearAlgebra: SingularException

export forward_substitution, back_substitution

"""
    forward_substitution(L, b; unit_diagonal = false)

下三角行列Lについて，Lx = bを前進代入で解く．Lの対角より上の要素は読まない．
`unit_diagonal = true`なら対角を1とみなし，対角の要素も読まない．
計算した解x̂は(L + ΔL)x̂ = b，|ΔL| ≤ γₙ|L|を満たす．
対角に0があれば`SingularException`を，大きさが合わなければ`DimensionMismatch`を投げる．
"""
function forward_substitution(L::AbstractMatrix{T}, b::AbstractVector{T}; unit_diagonal::Bool = false) where {T<:AbstractFloat}
    n = check_sizes(L, b)
    x = Vector{T}(b)
    for i in 1:n
        for j in 1:i-1
            x[i] -= L[i, j] * x[j]
        end
        if !unit_diagonal
            iszero(L[i, i]) && throw(SingularException(i))
            x[i] /= L[i, i]
        end
    end
    return x
end

"""
    back_substitution(U, b)

上三角行列Uについて，Ux = bを後退代入で解く．Uの対角より下の要素は読まない．
計算した解x̂は(U + ΔU)x̂ = b，|ΔU| ≤ γₙ|U|を満たす．
対角に0があれば`SingularException`を，大きさが合わなければ`DimensionMismatch`を投げる．
"""
function back_substitution(U::AbstractMatrix{T}, b::AbstractVector{T}) where {T<:AbstractFloat}
    n = check_sizes(U, b)
    x = Vector{T}(b)
    for i in n:-1:1
        for j in i+1:n
            x[i] -= U[i, j] * x[j]
        end
        iszero(U[i, i]) && throw(SingularException(i))
        x[i] /= U[i, i]
    end
    return x
end

# 行列が正方で，ベクトルの長さが行列の大きさと合うことを確かめ，大きさを返す．
function check_sizes(A::AbstractMatrix, b::AbstractVector)
    n = size(A, 1)
    size(A, 2) == n || throw(DimensionMismatch("三角行列は正方でなければならない(大きさ$(size(A)))"))
    length(b) == n || throw(DimensionMismatch("bの長さ$(length(b))が行列の大きさ$(n)と合わない"))
    return n
end

end
