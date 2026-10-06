"""
    ErrorBounds

誤差解析に使う定数(単位丸め，γₙ)と，計算結果の誤差を測る関数．
"""
module ErrorBounds

export unit_roundoff, gamma, relative_error

"""
    unit_roundoff(T)

浮動小数点数型`T`の単位丸めu = eps(T)/2を返す．
"""
unit_roundoff(::Type{T}) where {T<:AbstractFloat} = error("unit_roundoffは未実装")

"""
    gamma(n, T)

γₙ = nu/(1 - nu)を返す．uは`T`の単位丸めである．
nu ≥ 1のときは`ArgumentError`を投げる．
"""
gamma(n::Integer, ::Type{T}) where {T<:AbstractFloat} = error("gammaは未実装")

"""
    relative_error(computed, exact)

相対誤差|computed - exact|/|exact|を有理数で厳密に求め，`Float64`で返す．
`exact`が0のときは，`computed`も0なら0.0，そうでなければ`Inf`を返す．
"""
relative_error(computed::AbstractFloat, exact::Rational{BigInt}) = error("relative_errorは未実装")

end
