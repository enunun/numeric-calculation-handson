# テストリスト：Iteration 5

## 単体テスト

### ErrorBounds

- [x] Iteration 4の項目は変えずに通る
- [x] `ulp_error(1.0, big(1.0))`は0.0，`ulp_error(nextfloat(1.0), big(1.0))`は1.0
- [x] `ulp_error(prevfloat(1.0), big(1.0))`は0.5(正しい値の区間(1以上2未満)の間隔で測る)
- [x] `ulp_error(1.0, 1 - 2⁻⁵⁴)`は0.5(正しい値の区間(0.5以上1未満)の間隔で測る)
- [x] 非正規化数の範囲では間隔2⁻¹⁰⁷⁴で測る(0と最小の非正規化数，3·2⁻¹⁰⁷⁴と2⁻¹⁰⁷⁴)
- [x] 負の値は絶対値で測る

### ErrorFreeTransforms，Summation，Quadratic，Moments，Triangular，LinearSolve，LeastSquares

- [x] Iteration 4の項目は変えずに通る

### ElementaryFunctions

- [x] `reduce_argument(0.0)`は`(0, 0.0)`，`reduce_argument(0.25)`は`(0, 0.25)`
- [x] `reduce_argument(1.0)`のkは1
- [x] rの誤差は，rの丸め，k·LN2_LOの丸め，ln 2の分割誤差のk倍の和以下(大小さまざまなx)
- [x] |r| ≤ (ln 2/2)(1 + 2⁻⁴⁰)
- [x] `exponential(±0.0)`は1.0
- [x] `NaN`は`NaN`，`Inf`は`Inf`，`-Inf`は0.0
- [x] `exponential(710.0)`は`Inf`，`exponential(-746.0)`は0.0
- [x] 境界の近くの値(オーバーフローの直前，正規化数と非正規化数の境，0になる直前，±ln 2/2の前後，0の近く)でULP誤差が上界以下
- [x] 全範囲と0の近くの乱数の標本でULP誤差が上界以下(正規化数1.3 ULP，非正規化数1.8 ULP，10個のシード)
- [x] exp(x)·exp(−x)の相対誤差が2δ + δ²以下(δ = 2.6u，10個のシード)
- [x] `Base.exp`との差が2.3 ULP以下(差分テスト，10個のシードで10万点)

## 結合テスト

- [x] Iteration 4の項目は変えずに通る

## 局所的な全数検査

- [x] 1.0，ln 2/2，−ln 2/2，log(floatmin)の前後1万個ずつの連続する浮動小数点数で，ULP誤差が上界以下
