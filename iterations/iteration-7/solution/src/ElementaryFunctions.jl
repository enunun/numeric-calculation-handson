"""
    ElementaryFunctions

初等関数(指数関数)．引数還元と多項式近似で計算し，誤差の上界を誤差予算で示す．
"""
module ElementaryFunctions

export reduce_argument, exponential

# ln 2 = LN2_HI + LN2_LO(Cody–Waiteの分割)．LN2_HIの仮数の下位21ビットは0なので，
# |k| < 2²¹ならk·LN2_HIは丸めずに計算できる．分割の誤差|ln 2 - LN2_HI - LN2_LO|は約1.2 × 10⁻²⁶である．
const LN2_HI = 6.93147180369123816490e-01
const LN2_LO = 1.90821492927058770002e-10

# exp(r) = 1 + r + r²Q(r)の多項式Q(r) = Σⱼ rʲ/(j + 2)!(j = 0, …, 11)の係数．全体では13次のテイラー多項式である．
const Q_COEFFICIENTS = Tuple(1 / factorial(big(j + 2)) for j in 0:11) .|> Float64

"""
    reduce_argument(x)

x = k·ln 2 + r，|r| ≤ ln 2/2となる`(k, r)`を返す(kは整数)．
k = round(x/ln 2)とし，r = (x - k·LN2_HI) - k·LN2_LOで求める(Cody–Waiteの方法)．
k ≠ 0ならx - k·LN2_HIは丸めずに計算でき，rの誤差は最後の引き算の丸め(u|r|程度)が主になる．
"""
function reduce_argument(x::Float64)
    k = round(Int, x / log(2.0))
    r = (x - k * LN2_HI) - k * LN2_LO
    return (k, r)
end

"""
    exponential(x)

exp(x)を返す．x = k·ln 2 + rと還元し，exp(r)を1 + (r + r²Q(r))で近似して，2ᵏを掛ける．
誤差予算による上界は，結果が正規化数なら1.3 ULP，非正規化数なら1.8 ULPである．
`NaN`には`NaN`，`Inf`には`Inf`，`-Inf`には0.0を返す．x > 710では`Inf`，x < -746では0.0を返す．
"""
function exponential(x::Float64)
    isnan(x) && return x
    # この範囲の外では，結果は明らかにオーバーフロー(Inf)またはアンダーフロー(0.0)する．
    x > 710.0 && return Inf
    x < -746.0 && return 0.0
    k, r = reduce_argument(x)
    s = r + r * r * evalpoly(r, Q_COEFFICIENTS)
    # 2ᵏを掛けるのは，結果が正規化数なら厳密である．オーバーフローするとInf，非正規化数の範囲では丸められる．
    return ldexp(1.0 + s, k)
end

end
