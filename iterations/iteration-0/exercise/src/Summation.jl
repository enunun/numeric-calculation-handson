"""
    Summation

浮動小数点数のベクトルの総和と，総和の条件数．
"""
module Summation

export two_sum, naive_sum, compensated_sum, sum_condition_number

"""
    two_sum(a, b)

`(s, e)`を返す．s = fl(a + b)で，a + b = s + eが厳密に成り立つ．
"""
two_sum(a::T, b::T) where {T<:AbstractFloat} = error("two_sumは未実装")

"""
    naive_sum(xs)

先頭から順に足した総和を返す．
"""
naive_sum(xs::AbstractVector{T}) where {T<:AbstractFloat} = error("naive_sumは未実装")

"""
    compensated_sum(xs)

補償付きの総和(Ogita–Rump–OishiのSum2)を返す．
"""
compensated_sum(xs::AbstractVector{T}) where {T<:AbstractFloat} = error("compensated_sumは未実装")

"""
    sum_condition_number(xs)

総和の条件数Σ|xᵢ|/|Σxᵢ|を返す．総和が0なら`Inf`を返す．
"""
sum_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat} = error("sum_condition_numberは未実装")

end
