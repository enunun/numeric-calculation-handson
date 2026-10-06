# モジュール依存図

`StableNumerics`を構成するモジュールと，その依存関係を示す．
矢印`A --> B`は，`A`が`B`の関数を使うことを表す．

```mermaid
flowchart LR
    StableNumerics --> ErrorBounds
    StableNumerics --> ErrorFreeTransforms
    StableNumerics --> Summation
    StableNumerics --> Quadratic
    StableNumerics --> Moments
    StableNumerics --> Triangular
    StableNumerics --> LinearSolve
    StableNumerics --> LeastSquares
    Summation --> ErrorFreeTransforms
    Quadratic --> ErrorFreeTransforms
    Moments --> Summation
    LinearSolve --> Triangular
    LeastSquares --> Triangular
    LeastSquares --> LinearSolve
```

- `StableNumerics`は，各モジュールの関数を公開する．`StableNumerics`自身は計算をしない．
- `ErrorBounds`は，誤差解析の定数(単位丸めu，γₙ)と，誤差の測り方(有理数または`BigFloat`の参照解に対する相対誤差)を受け持つ．
- `ErrorFreeTransforms`は，和と積の無誤差変換(`two_sum`，`two_prod`)を受け持つ．
- `Summation`は，総和の計算と総和の条件数を受け持つ．補償付き総和で`two_sum`を使う．
- `Quadratic`は，二次方程式の判別式と実根，根の後退誤差と条件数を受け持つ．判別式の計算で`two_prod`を使う．
- `Moments`は，平均，標本分散，分散の条件数を受け持つ．平均の和を`compensated_sum`で求める．
- `Triangular`は，三角行列を係数とする連立1次方程式の解法(前進代入，後退代入)を受け持つ．
- `LinearSolve`は，LU分解，連立1次方程式の解法，解の後退誤差，分解の増大因子を受け持つ．解法の前進代入と後退代入は`Triangular`を使う．
- `LeastSquares`は，ハウスホルダー変換によるQR分解，最小二乗問題の解法(QR分解，正規方程式)，多項式の当てはめを受け持つ．Rx = cを`Triangular`の後退代入で，正規方程式を`LinearSolve`のLU分解で解く．
- `Triangular`，`LinearSolve`，`LeastSquares`は，標準ライブラリ`LinearAlgebra`の`SingularException`などを使う．
- テストは，`ErrorBounds`の関数で許容誤差と実際の誤差を求める．性質ベーステストのデータは，標準ライブラリ`Random`で作る．条件数を指定したテスト行列は，`LinearAlgebra`の`qr`で作る．
