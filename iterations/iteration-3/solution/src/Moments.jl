"""
    Moments

データの平均，標本分散，分散の条件数．
"""
module Moments

using ..Summation: compensated_sum

export mean, variance, textbook_variance, variance_condition_number

"""
    mean(xs)

平均Σxᵢ/nを返す．和は`compensated_sum`で求める．
空のベクトルでは`ArgumentError`を投げる．
"""
function mean(xs::AbstractVector{T}) where {T<:AbstractFloat}
    isempty(xs) && throw(ArgumentError("空のデータの平均は定義されない"))
    return compensated_sum(xs) / length(xs)
end

"""
    variance(xs)

標本分散S/(n - 1)(Sは偏差平方和)を，Welfordの算法でデータを1回走査して求める．
k番目のデータxₖで，平均mと偏差平方和Sを次のように更新する．

    d = xₖ - m,   m ← m + d/k,   S ← S + d(xₖ - m)

結果は負にならない．相対誤差は，一次の見積もりでnκu程度である(κは分散の条件数)．
要素数が2未満なら`ArgumentError`を投げる．
"""
function variance(xs::AbstractVector{T}) where {T<:AbstractFloat}
    length(xs) < 2 && throw(ArgumentError("分散には2つ以上のデータが必要である"))
    m = zero(T)
    S = zero(T)
    for (k, x) in enumerate(xs)
        d = x - m
        m += d / k
        S += d * (x - m)
    end
    return S / (length(xs) - 1)
end

"""
    textbook_variance(xs)

教科書の公式(Σxᵢ² - (Σxᵢ)²/n)/(n - 1)で標本分散を求める．比較のための関数である．
相対誤差の上界は，一次の近似で(3n + 1)u·κ² + 2uであり，条件数が大きいと負の値を返すこともある．
要素数が2未満なら`ArgumentError`を投げる．
"""
function textbook_variance(xs::AbstractVector{T}) where {T<:AbstractFloat}
    length(xs) < 2 && throw(ArgumentError("分散には2つ以上のデータが必要である"))
    n = length(xs)
    total = zero(T)
    squares = zero(T)
    for x in xs
        total += x
        squares += x * x
    end
    return (squares - total * total / n) / (n - 1)
end

"""
    variance_condition_number(xs)

偏差平方和Sの条件数‖x‖₂/√Sを返す．
‖x‖₂²とSを有理数で厳密に求め，平方根を`BigFloat`で計算して`Float64`へ丸める．
S = 0(すべての値が等しい)なら`Inf`を返す．要素数が2未満なら`ArgumentError`を投げる．
"""
function variance_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat}
    length(xs) < 2 && throw(ArgumentError("分散には2つ以上のデータが必要である"))
    values = Rational{BigInt}.(xs)
    squares = sum(abs2, values)
    deviation_sum = squares - sum(values)^2 / length(values)
    iszero(deviation_sum) && return Inf
    return Float64(sqrt(BigFloat(squares / deviation_sum)))
end

end
