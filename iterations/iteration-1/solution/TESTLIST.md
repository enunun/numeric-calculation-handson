# テストリスト：Iteration 1

## 単体テスト

### ErrorBounds

- [x] `unit_roundoff(Float64)`は2⁻⁵³(`==`で比べる)
- [x] `unit_roundoff(Float32)`は2⁻²⁴(`==`で比べる)
- [x] `gamma(n, Float64)`の相対誤差が，有理数で求めたnu/(1 − nu)に対してγ₂以下(n = 1，10，1000，2⁴⁰)
- [x] `gamma(1000, Float64)`は1000uより大きい
- [x] nu ≥ 1となるn(2⁵³)では`ArgumentError`を投げる
- [x] `relative_error`は，正しい値と一致すれば0.0
- [x] `relative_error(0.75, 1//2)`は0.5(負の値でも同じ)
- [x] `relative_error(0.1, 1//10)`は0より大きくu以下
- [x] 正しい値が0のとき，計算値も0なら0.0，そうでなければ`Inf`
- [x] `relative_error(0.5, big(0.5))`は0.0，`relative_error(0.75, big(0.5))`は0.5
- [x] `BigFloat`の正しい値が0のとき，計算値も0なら0.0，そうでなければ`Inf`
- [x] `relative_error(sqrt(2.0), sqrt(big(2)))`はu以下
- [x] `relative_error(0.1, big(1)/10)`と`relative_error(0.1, 1//10)`の相対差は2u以下

### ErrorFreeTransforms

- [x] `two_sum`のテストを`test/unit/summation_tests.jl`から移す(4項目)
- [x] `two_prod(3.0, 0.5)`は`(1.5, 0.0)`(積が厳密に表せれば誤差の項は0)
- [x] `two_prod(0.1, 0.1)`は`(0.1 * 0.1, -8.326672684688674e-19)`
- [x] `two_prod`のpは`a * b`に等しい(大きさや符号の違う6組)
- [x] `two_prod`はa × b = p + eを厳密に満たす(有理数で比べる，同じ6組)

### Summation

- [x] `two_sum`以外の項目は変えずに通る

### Quadratic

- [x] `discriminant(1.0, -3.0, 2.0)`は1.0，`discriminant(1.0, 0.0, 1.0)`は-4.0
- [x] `discriminant`の相対誤差はγ₄以下(桁落ちする係数，Kahanの例，根が近い係数を含む)
- [x] `quadratic_roots(1.0, -3.0, 2.0)`は`(1.0, 2.0)`(aが負でも同じ)
- [x] 重根`quadratic_roots(1.0, -2.0, 1.0)`は`(1.0, 1.0)`
- [x] 根が0の重根`quadratic_roots(1.0, 0.0, 0.0)`は`(0.0, 0.0)`
- [x] 判別式が負なら`nothing`(-4の場合と，-4·2⁻⁵²の場合)
- [x] a = 0なら`ArgumentError`
- [x] 係数のどれかが`Inf`，`-Inf`，`NaN`なら`ArgumentError`
- [x] 実根の有無が，厳密な判別式の符号と一致する
- [x] 根は小さい順に並ぶ
- [x] 各根の相対誤差はγ₆以下(`BigFloat`の参照解と比べる)
- [x] 参照解は，精度を256ビットから512ビットに上げても相対差u²以下でしか変わらない
- [x] 解と係数の関係：|r̂₁ + r̂₂ + b/a| ≤ (γ₆/(1 − γ₆))(|r̂₁| + |r̂₂|)
- [x] 解と係数の関係：|r̂₁r̂₂ − c/a| ≤ γ₁₂|c/a|
- [x] 正確な根の`root_backward_error`は0.0
- [x] `root_backward_error(1.0, -3.0, 2.0, 1.5)`は1/35
- [x] 計算した根の後退誤差はγ₁₂以下
- [x] `root_condition_number(1.0, -3.0, 2.0, r)`はr = 1，2のどちらでも6.0
- [x] 重根と根0の`root_condition_number`は`Inf`
- [x] 2つの根が近づくほど`root_condition_number`は大きくなる(δ = 10⁻⁴，10⁻⁷，10⁻¹⁰)

## 結合テスト

- [x] 総和の精度の見積もり(Iteration 0の項目)は変えずに通る
- [x] 公開APIだけで，計算したすべての根の後退誤差がγ₁₂以下であることを確かめる
- [x] Kahanの例では，κ_r·uはγ₆より大きいが，実際の相対誤差はγ₆以下に収まる
