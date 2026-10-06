"""
    Summation

浮動小数点数のベクトルの総和と，総和の条件数．
"""
module Summation

export two_sum, naive_sum, compensated_sum, sum_condition_number

"""
    two_sum(a, b)

`(s, e)`を返す．s = fl(a + b)で，a + b = s + eが厳密に成り立つ(Knuthの無誤差変換)．
オーバーフローが起きない限り，aとbの大小や符号によらず成り立つ．
"""
function two_sum(a::T, b::T) where {T<:AbstractFloat}
    s = a + b
    b_virtual = s - a
    a_virtual = s - b_virtual
    e = (a - a_virtual) + (b - b_virtual)
    return (s, e)
end

"""
    naive_sum(xs)

先頭から順に足した総和を返す．相対誤差の上界はγₙ₋₁·κである(κは総和の条件数)．
"""
function naive_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}
    s = zero(T)
    for x in xs
        s += x
    end
    return s
end

"""
    compensated_sum(xs)

補償付きの総和(Ogita–Rump–OishiのSum2)を返す．
`two_sum`で各段の丸め誤差を取り出して別に足し合わせ，最後に和へ加える．
相対誤差の上界はu + γₙ₋₁²·κである(κは総和の条件数)．
"""
function compensated_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}
    s = zero(T)
    c = zero(T)
    for x in xs
        s, e = two_sum(s, x)
        c += e
    end
    return s + c
end

"""
    sum_condition_number(xs)

総和の条件数Σ|xᵢ|/|Σxᵢ|を返す．分母は`compensated_sum`で求める．
総和が0なら`Inf`を返す．
"""
function sum_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat}
    total = compensated_sum(xs)
    iszero(total) && return T(Inf)
    return naive_sum(map(abs, xs)) / abs(total)
end

end
