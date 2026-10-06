using StableNumerics.ErrorBounds
using StableNumerics.ElementaryFunctions

# 連続する浮動小数点数を区間ごとにすべて調べる(局所的な全数検査)．
# 誤差が大きくなりやすい点(還元の切り替わり，1の近く，非正規化数の始まり)の前後を選ぶ．

"""
    consecutive_floats(center, count)

centerの前後count個ずつの連続する浮動小数点数を返す．
"""
function consecutive_floats(center, count)
    xs = [center]
    lower, upper = center, center
    for _ in 1:count
        lower = prevfloat(lower)
        upper = nextfloat(upper)
        push!(xs, lower, upper)
    end
    return sort(xs)
end

@testset "exponential：局所的な全数検査 中心 = $(center)" for center in (1.0, log(2.0) / 2, -log(2.0) / 2, log(floatmin(Float64)))
    worst = 0.0
    for x in consecutive_floats(center, 10_000)
        worst = max(worst, ulp_error(exponential(x), reference_exp(x)) / exp_ulp_bound(x))
    end
    # 許容誤差に対する割合の最大値が1以下．
    @test worst <= 1
end
