# テストリスト：Iteration 6

## 単体テスト

### ErrorBounds，ErrorFreeTransforms，Summation，Quadratic，Moments，Triangular，LinearSolve，LeastSquares，ElementaryFunctions

- [x] Iteration 5の項目は変えずに通る

### ODESolvers

- [x] `euler_step`はy + h·f(t, y)を返す(丸めの起きない入力で`==`)
- [x] `rk4_step`は，右辺がtだけの3次以下の多項式なら厳密(y′ = 4t³，y′ = 3t² + 1)
- [x] `rk4_step`は，右辺がtの4次式(y′ = 5t⁴)では厳密ではない
- [x] `integrate`で1ステップなら`step`を1回呼んだ結果と一致する
- [x] `integrate`は時刻t₀ + k·hで`step`をn回呼ぶ(Euler法4ステップを手で並べた結果と一致)
- [x] n < 1なら`ArgumentError`
- [x] `BigFloat`の初期値なら`BigFloat`の結果を返す
- [x] `observed_order(1.0, 0.5)`は1.0，`observed_order(16.0, 1.0)`は4.0
- [x] `richardson_error_estimate`は(y_coarse − y_fine)/(2ᵖ − 1)
- [x] 製造解の問題で，Euler法の観測次数のずれは，hを半分にしたときの比が0.6以下(`BigFloat`，n = 2³〜2⁹)
- [x] 同じく，RK4の観測次数のずれの比も0.6以下
- [x] `Float64`の丸め誤差は，打ち切り誤差の1%以下(Euler法とRK4，n = 2³〜2⁹)
- [x] リチャードソン外挿の推定の相対誤差は，hを半分にしたときの比が0.6以下(RK4，`BigFloat`)

## 結合テスト

- [x] Iteration 5の項目は変えずに通る
- [x] 振り子で，隣り合う刻み幅の解の差から求めた観測次数のずれの比が0.6以下(分割数：Euler法n = 2⁸〜2¹³，RK4 n = 2⁴〜2⁹)

## 局所的な全数検査

- [x] Iteration 5の項目は変えずに通る
