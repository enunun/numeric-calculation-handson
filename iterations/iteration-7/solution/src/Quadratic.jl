"""
    Quadratic

二次方程式の実根と，根の後退誤差・条件数．
"""
module Quadratic

using ..ErrorFreeTransforms: two_prod

export discriminant, quadratic_roots, root_backward_error, root_condition_number

"""
    discriminant(a, b, c)

判別式b² - 4acを返す．
b²と4acが近く打ち消し合うときは，`two_prod`で取り出した積の丸め誤差を加えて桁落ちを補う(Kahanの方法)．
オーバーフローとアンダーフローが起きなければ，相対誤差はγ₄以下である．
"""
function discriminant(a::T, b::T, c::T) where {T<:AbstractFloat}
    p, p_error = two_prod(b, b)
    q, q_error = two_prod(4a, c)
    d = p - q
    # 3|d| ≥ p + |q|なら打ち消しは小さく，そのままで十分正確である．
    3 * abs(d) >= p + abs(q) && return d
    # pとqは2倍以内に近いので，p - qは厳密に計算されている．積の丸め誤差を加える．
    return d + (p_error - q_error)
end

"""
    quadratic_roots(a, b, c)

ax² + bx + c = 0の実根を小さい順に`(r₁, r₂)`で返す．実根がなければ`nothing`を返す．
絶対値の大きい根をq/a，小さい根をc/qで求める(q = -(b + sign(b)√d)/2)．bとsign(b)√dは同符号なので，qの計算で桁落ちは起きない．
オーバーフローとアンダーフローが起きなければ，各根の相対誤差はγ₆以下である．
a = 0のときと，係数が有限でないときは`ArgumentError`を投げる．
"""
function quadratic_roots(a::T, b::T, c::T) where {T<:AbstractFloat}
    iszero(a) && throw(ArgumentError("aが0の方程式は二次方程式ではない"))
    (isfinite(a) && isfinite(b) && isfinite(c)) || throw(ArgumentError("係数は有限でなければならない"))
    d = discriminant(a, b, c)
    d < 0 && return nothing
    q = -(b + copysign(sqrt(d), b)) / 2
    # q = 0となるのはb = 0かつd = 0，すなわちc = 0のときで，根は0の重根である．
    iszero(q) && return (zero(T), zero(T))
    return minmax(q / a, c / q)
end

"""
    root_backward_error(a, b, c, r)

rを根とする係数の相対的な摂動の大きさ(成分ごとの後退誤差)|p(r)|/(|a|r² + |b||r| + |c|)を返す．
p(r) = ar² + br + cは有理数で厳密に計算し，結果を`Float64`へ丸める．
"""
function root_backward_error(a::T, b::T, c::T, r::T) where {T<:AbstractFloat}
    A, B, C, R = Rational{BigInt}.((a, b, c, r))
    scale = abs(A) * R^2 + abs(B) * abs(R) + abs(C)
    iszero(scale) && return 0.0
    return Float64(abs(A * R^2 + B * R + C) / scale)
end

"""
    root_condition_number(a, b, c, r)

単根rの，係数の成分ごとの相対的な摂動に対する条件数(|a|r² + |b||r| + |c|)/|r·p′(r)|を返す．
有理数で厳密に計算し，結果を`Float64`へ丸める．重根(p′(r) = 0)とr = 0では`Inf`を返す．
"""
function root_condition_number(a::T, b::T, c::T, r::T) where {T<:AbstractFloat}
    A, B, C, R = Rational{BigInt}.((a, b, c, r))
    denominator = abs(R * (2A * R + B))
    iszero(denominator) && return Inf
    return Float64((abs(A) * R^2 + abs(B) * abs(R) + abs(C)) / denominator)
end

end
