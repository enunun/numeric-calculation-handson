# テストリスト：Iteration 4

## 単体テスト

### ErrorBounds，ErrorFreeTransforms，Summation，Quadratic，Moments

- [x] Iteration 3の項目は変えずに通る

### Triangular

- [x] 前進代入で2x₁ = 4，x₁ + 4x₂ = 10を解くと`[2.0, 2.0]`
- [x] `unit_diagonal = true`では対角を1とみなし，対角と上の要素を読まない
- [x] 前進代入で対角に0があれば`SingularException`，大きさが合わなければ`DimensionMismatch`
- [x] 後退代入で2x₁ + x₂ = 5，4x₂ = 8を解くと`[1.5, 2.0]`
- [x] 後退代入は対角より下の要素を読まない
- [x] 後退代入で対角に0があれば`SingularException`，大きさが合わなければ`DimensionMismatch`
- [x] 成分ごとの後退誤差はγₙ以下(上三角と下三角，条件数1〜10⁸の乱数の行列，50個のシード)

### LinearSolve

- [x] リファクタリング(`solve`が`Triangular`を使う)の後も，Iteration 3の項目は変えずに通る

### LeastSquares

- [x] `householder_qr`のRはn × nの上三角，`q_factor`はm × n
- [x] 行数が列数より少なければ`ArgumentError`
- [x] ‖Q̂ᵀQ̂ − I‖₂ ≤ γ₂ₘₙ(条件数1〜10¹⁰の乱数の行列，50個のシード)
- [x] 列ごとに‖aⱼ − (Q̂R̂)ⱼ‖₂ ≤ γ₂ₘₙ‖aⱼ‖₂(同じ行列)
- [x] 列がe₁にほぼ平行な行列(第1要素が±1，ほかが10⁻⁴〜10⁻¹²)でも，直交性と再構成の誤差界が成り立つ
- [x] 列が0の行列の`lstsq_qr`は`SingularException`，行数が列数より少なければ`ArgumentError`
- [x] 製造解の残差はAの列と厳密に直交する
- [x] 製造解で，`lstsq_qr`の前進誤差はγ₂ₘₙ(κ₂ + κ₂²ρ)以下(50個のシード)
- [x] 乱数の行列で，`lstsq_qr`の前進誤差は，有理数で求めた厳密解に対してγ₂ₘₙ(κ₂ + κ₂²ρ)以下(50個のシード)
- [x] 最適性条件：‖Aᵀr̂‖₂ ≤ γ₂ₘₙ‖A‖₂(‖A‖₂‖x̂‖₂ + ‖b‖₂ + ‖r̂‖₂)(同じ行列)
- [x] 製造解で，`lstsq_normal`の前進誤差はγ₂ₘₙκ₂²以下(50個のシード)
- [x] 点の数がdegree + 1より少なければ`polyfit`は`ArgumentError`
- [x] 整数の点(0〜19)での整数係数の多項式(1〜5次)の値から，`polyfit`は係数をγ₂ₘₙκ₂以下の相対誤差で求める(製造解)

## 結合テスト

- [x] Iteration 3の項目は変えずに通る
- [x] 50点に9次の多項式を当てはめると，`polyfit`の前進誤差は許容誤差γ₂ₘₙ(κ₂ + κ₂²ρ)以下で，`lstsq_qr`と同じ結果になり，`lstsq_normal`の前進誤差は許容誤差を超える
