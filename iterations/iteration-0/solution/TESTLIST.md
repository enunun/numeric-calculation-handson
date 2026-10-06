# テストリスト：Iteration 0

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

### Summation

- [x] `two_sum(1.0, 2.0)`は`(3.0, 0.0)`(丸めが起きなければ誤差の項は0)
- [x] `two_sum(1e16, 1.0)`は`(1e16, 1.0)`(丸めで失われた1が誤差の項に残る)
- [x] `two_sum`のsは`a + b`に等しい(大きさや符号の違う5組)
- [x] `two_sum`はa + b = s + eを厳密に満たす(有理数で比べる，同じ5組)
- [x] `naive_sum`は，空のベクトルで0.0
- [x] `naive_sum([1.0, 2.0, 3.0])`は6.0(整数の和は厳密)
- [x] `naive_sum([1e16, 1.0, -1e16])`は0.0(情報落ち)
- [x] `naive_sum`の相対誤差はγₙ₋₁·κ以下(条件数が1〜10¹⁶程度の5種類のデータ)
- [x] `compensated_sum`は，空のベクトルで0.0
- [x] `compensated_sum([1e16, 1.0, -1e16])`は1.0
- [x] `compensated_sum(fill(0.1, 10))`は，厳密な和を最も近い倍精度数に丸めた値
- [x] `compensated_sum`の相対誤差がu + γₙ₋₁²·κ以下(同じ5種類のデータ)
- [x] `sum_condition_number`は，符号がそろったデータで1.0
- [x] `sum_condition_number([1e16, 1.0, -1e16])`は2e16
- [x] 和が0なら`sum_condition_number`は`Inf`
- [x] `sum_condition_number`は，有理数で求めた条件数と，分子・分母・割り算の誤差から導いた許容誤差の中で一致する(5種類のデータ)

## 結合テスト

- [x] 公開APIだけを使い，`sum_condition_number`で求めた条件数から見積もった誤差界に，`naive_sum`と`compensated_sum`の実際の誤差が収まる(5種類のデータ)
