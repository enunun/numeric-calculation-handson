"""
    ErrorFreeTransforms

無誤差変換：浮動小数点数の演算の結果を，丸めた結果と丸め誤差の組に誤差なく分解する．
"""
module ErrorFreeTransforms

export two_sum, two_prod

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
    two_prod(a, b)

`(p, e)`を返す．p = fl(a × b)で，a × b = p + eが厳密に成り立つ．
eはfma(融合積和演算)でa × b - pを1回の丸めで計算して求める．
オーバーフローとアンダーフローが起きない限り成り立つ．
"""
function two_prod(a::T, b::T) where {T<:AbstractFloat}
    p = a * b
    e = fma(a, b, -p)
    return (p, e)
end

end
