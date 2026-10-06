"""
    ErrorBounds

誤差解析に使う定数(単位丸め，γₙ)と，計算結果の誤差を測る関数．
"""
module ErrorBounds

export unit_roundoff, gamma, relative_error

"""
    unit_roundoff(T)

浮動小数点数型`T`の単位丸めu = eps(T)/2を返す．
最近接丸めでは，表現できる範囲の実数xについて|fl(x) - x| ≤ u|x|が成り立つ．
"""
unit_roundoff(::Type{T}) where {T<:AbstractFloat} = eps(T) / 2

"""
    gamma(n, T)

γₙ = nu/(1 - nu)を返す．uは`T`の単位丸めである．
|δᵢ| ≤ uのとき，n個の(1 + δᵢ)^(±1)の積は1 + θ(|θ| ≤ γₙ)と書ける．
nu ≥ 1のときは`ArgumentError`を投げる．
"""
function gamma(n::Integer, ::Type{T}) where {T<:AbstractFloat}
    nu = n * unit_roundoff(T)
    nu < 1 || throw(ArgumentError("gamma(n, T)はn*u < 1のときだけ定義される(n = $n)"))
    return nu / (1 - nu)
end

"""
    relative_error(computed, exact)

相対誤差|computed - exact|/|exact|を返す．
`computed`(有限の浮動小数点数)を有理数に直して厳密に計算し，最後に`Float64`へ丸める．
`exact`が0のときは，`computed`も0なら0.0，そうでなければ`Inf`を返す．
"""
function relative_error(computed::AbstractFloat, exact::Rational{BigInt})
    if iszero(exact)
        return iszero(computed) ? 0.0 : Inf
    end
    return Float64(abs(Rational{BigInt}(computed) - exact) / abs(exact))
end

"""
    relative_error(computed, exact::BigFloat)

相対誤差|computed - exact|/|exact|を，`BigFloat`の精度で計算して`Float64`で返す．
`exact`が高精度の参照解(真の値との相対誤差がuより十分小さい値)であることを前提とする．
`exact`が0のときの扱いは，有理数のメソッドと同じである．
"""
function relative_error(computed::AbstractFloat, exact::BigFloat)
    if iszero(exact)
        return iszero(computed) ? 0.0 : Inf
    end
    return Float64(abs(BigFloat(computed) - exact) / abs(exact))
end

end
