# テストリスト：Iteration 2

## 単体テスト

### ErrorBounds，ErrorFreeTransforms，Summation，Quadratic

- [x] Iteration 1の項目は変えずに通る

### Moments

- [x] `mean([1.0, 2.0, 3.0, 4.0])`は2.5
- [x] `mean([1e16, 1.0, -1e16])`は1/3(補償付き総和で和が1.0になる)
- [x] 空のベクトルの`mean`は`ArgumentError`
- [x] `mean`の相対誤差はβ + u + βu以下(β = u + γₙ₋₁²κ，Iteration 0の5種類のデータ)
- [x] `variance([1.0, 2.0, 3.0, 4.0])`は5/3
- [x] `variance([1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16])`は30.0
- [x] 要素数が0と1の`variance`は`ArgumentError`
- [x] `variance`は負にならない(乱数のデータ，50個のシード)
- [x] 定数のデータの`variance`は厳密に0(同じシード)
- [x] データを2ᵏ倍すると`variance`は厳密に4ᵏ倍になる(同じシード，kも乱数で選ぶ)
- [x] `variance`の相対誤差はγ₂ₙ·κ_v以下(条件数1〜10⁸のデータ，50個のシード)
- [x] 整数値のデータに2の冪を足しても，`variance`の変化は2つの許容誤差の和以下(50個のシード)
- [x] データを並べ替えても，`variance`の変化は許容誤差の2倍以下(同じシード)
- [x] `textbook_variance([1.0, 2.0, 3.0, 4.0])`は5/3
- [x] 要素数が1の`textbook_variance`は`ArgumentError`
- [x] `textbook_variance([1e9 + 4, 1e9 + 7, 1e9 + 13, 1e9 + 16])`は負になる
- [x] `textbook_variance`の相対誤差はγ₃ₙ₊₁·κ_v² + γ₂以下(条件数1〜10⁴のデータ，50個のシード)
- [x] `variance_condition_number([1.0, -1.0])`は1.0
- [x] `variance_condition_number([1.0, 2.0, 3.0])`は√7(相対誤差u以下)
- [x] 定数のデータの`variance_condition_number`は`Inf`
- [x] 要素数が1の`variance_condition_number`は`ArgumentError`

## 結合テスト

- [x] Iteration 1の項目は変えずに通る
- [x] 平均が標準偏差の10⁸倍のデータで，`variance_condition_number`から見積もると，教科書の公式の誤差の上界は1を超え，Welfordの算法の上界は1より小さい．実際の誤差はWelfordの上界以下で，平均の誤差はβ + u + βu以下(50個のシード)
