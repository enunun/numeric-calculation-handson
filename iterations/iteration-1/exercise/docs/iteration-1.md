# Iteration 1の手順：二次方程式と後退誤差

このIterationでは，二次方程式の実根を求める関数を作る．
根の公式の桁落ちを避け，判別式をfmaで正確に計算する．
計算結果の誤差を，問題の条件数とアルゴリズムの後退誤差に分けて考える．
作業はすべて`iterations/iteration-1/exercise/`で行う．

## 1-1 準備

1. 演習のパッケージを有効にしてREPLを起動し，Pkgモードで`test`を実行する．Iteration 0の模範解答のテストがすべて通る．

   ```text
   Test Summary:  | Pass  Total  Time
   StableNumerics |   60     60  1.8s
        Testing StableNumerics tests passed
   ```

2. リポジトリのルートで，設計文書の検査が通ることを確かめる．

   ```sh
   mise run design iterations/iteration-1/exercise
   ```

3. `src/`，`test/`，`design/`を読み，Iteration 0の終わりの状態を思い出す．

## 1-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-1.md)と[理論のノート](../../../../docs/theory/iteration-1.md)を読み，REPLで次の課題を解く．

1. `(-1e8 + sqrt(1e16 - 4)) / 2`を計算し，`x² + 10⁸x + 1 = 0`の小さい根(約−1.0e-8)と比べる．相対誤差はどれくらいか．
2. `a, b, c = 94906265.625, -189812534.0, 94906268.375`について，`b^2 - 4a * c`を計算する．`Rational{BigInt}`で厳密に計算した判別式と比べる．
3. `p = 0.1 * 0.1`と`fma(0.1, 0.1, -p)`を計算し，`Rational{BigInt}(0.1)^2`と`Rational{BigInt}(p) + Rational{BigInt}(fma(0.1, 0.1, -p))`が等しいことを確かめる．
4. `setprecision(BigFloat, 64) do ... end`と`setprecision(BigFloat, 256) do ... end`の中で`sqrt(BigFloat(2))`を計算し，表示される桁数を比べる．
5. 2つの引数の型によって違う文字列を返す関数を，メソッドを2つ定義して作る．`methods`で，その関数のメソッドの一覧を表示する．
6. 根r = 1，係数(1, −3, 2)について，後退誤差|p(r)|/(|a|r² + |b||r| + |c|)と条件数(|a|r² + |b||r| + |c|)/|r·p′(r)|を手で計算する．r = 1.5ではどうなるか．

## 1-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 実係数の二次方程式ax² + bx + c = 0(a ≠ 0)の実根を，小さい順に組で返す．実根がなければ`nothing`を返す．重根は同じ値を2つ返す．
- 係数の大きさが極端に違っても(例：b² ≫ |4ac|)，桁落ちせずに両方の根を求める．
- 判別式b² − 4acを，b²と4acが近いときにも正確に計算する．
- a = 0のときと，係数に`Inf`や`NaN`を含むときは`ArgumentError`を投げる．
- 計算した根の後退誤差と，根の条件数を求められる．
- 相対誤差を高精度の参照解(`BigFloat`)とも比べられる．
- 和と積の無誤差変換を，1つのモジュールにまとめる．

### 使用例

```julia
julia> quadratic_roots(1.0, 1e8, 1.0)
(-1.0e8, -1.0e-8)

julia> quadratic_roots(1.0, -2.0, 1.0)
(1.0, 1.0)

julia> quadratic_roots(1.0, 0.0, 1.0) === nothing
true

julia> quadratic_roots(94906265.625, -189812534.0, 94906268.375)
(1.0, 1.0000000289759583)

julia> two_prod(0.1, 0.1)
(0.010000000000000002, -8.326672684688674e-19)
```

### 作るもの

- `ErrorFreeTransforms`(新規)：`two_sum`を`Summation`から移し，`two_prod(a::T, b::T) where {T<:AbstractFloat}`を加える．`two_prod`は`(p, e)`を返す．p = fl(a × b)，a × b = p + e．
- `Summation`：`two_sum`を`ErrorFreeTransforms`から使う．
- `Quadratic`(新規)
  - `discriminant(a::T, b::T, c::T) where {T<:AbstractFloat}`
  - `quadratic_roots(a::T, b::T, c::T) where {T<:AbstractFloat}`：`Union{Nothing, Tuple{T, T}}`を返す．
  - `root_backward_error(a::T, b::T, c::T, r::T) where {T<:AbstractFloat}`：|p(r)|/(|a|r² + |b||r| + |c|)を返す．
  - `root_condition_number(a::T, b::T, c::T, r::T) where {T<:AbstractFloat}`：(|a|r² + |b||r| + |c|)/|r·p′(r)|を返す．重根とr = 0では`Inf`．
- `ErrorBounds`：`relative_error(computed::AbstractFloat, exact::BigFloat)`のメソッドを加える．

### 考えること

- `two_sum`のテストは，どのファイルに置くべきか．既存のテストのうち，移すものと変えないものを分けてリストに書く．
- 根の参照解をどう作るか．判別式は有理数で厳密に求められるか．平方根はどうするか．参照解の精度は十分か，どう確かめるか．
- 根の誤差界は，前進誤差(参照解との相対誤差)と後退誤差のどちらで書くか．条件の悪い係数(根が近い係数)ではどうなるか．
- 参照解を使わずに確かめられる性質はあるか．
- 特殊値と境界：a = 0，`Inf`，`NaN`，−0.0，重根，根が0，判別式がわずかに負．
- 根の順序は仕様のどこで決まっているか．

## 1-4 設計文書

- `design/modules.md`：新しい2つのモジュールを加える．`Summation`と`Quadratic`は，どのモジュールのどの関数を使うか．
- `design/error-spec.md`：
  - `two_sum`の行の「検証するテスト」を，テストを移す先のファイルに変える．
  - `two_prod`，`discriminant`，`quadratic_roots`，`root_backward_error`，`root_condition_number`の行を加える．
  - `quadratic_roots`の誤差界は，理論のノートの7節を参考に，計算の段階ごとに相対誤差を積み上げて導く．表の下に導き方を書く．
  - 表のセルの中で絶対値記号`|`を使うと列が崩れる．式は表の前で定義して記号で参照する．
- `design/adr/0002-stable-quadratic-formula.md`(新規)：根の公式の書き換えと，判別式の計算方法を選んだ理由を書く．素朴な判別式を使った場合，前進誤差と後退誤差がそれぞれどうなるかも書く．

書いたら`mise run design iterations/iteration-1/exercise`で検査する．

## 1-5 テストファーストの実装

### リファクタリング：two_sumを移す

振る舞いを変えずに構造を変えるリファクタリングから始める．

1. `test/unit/error_free_transforms_tests.jl`を作り，`two_sum`のテストを`test/unit/summation_tests.jl`から移す．`test/runtests.jl`に登録して実行し，`ErrorFreeTransforms`がないことで失敗するのを確かめる．
2. `src/ErrorFreeTransforms.jl`を作り，`two_sum`を移す．`src/StableNumerics.jl`で`include`し，公開する．
3. `Summation`は`using ..ErrorFreeTransforms: two_sum`で`two_sum`を使う．
4. すべてのテストが通ることを確かめる．テストの件数がリファクタリングの前と変わらないことも確かめる．

実装の途中は，単体テストだけを実行すると速い．
パッケージを有効にしたREPLで次のように実行する．

```julia
julia> using Pkg

julia> Pkg.test(test_args = ["unit"])
```

### ErrorFreeTransforms

- `two_prod`は`fma`で書ける．テストは`two_sum`と同じく，有理数に直して厳密に比べる．
- 無誤差変換の検査に使う組は，`two_sum`と`two_prod`で共通にできる．`test/helpers.jl`に置く．

### ErrorBounds

- `BigFloat`のメソッドは，`computed`を`BigFloat`に変換してから引き算する．
- 2つのメソッドの結果を比べるテストを書くなら，許容誤差を決める根拠を考える．

### Quadratic

- 参照解は`test/helpers.jl`に関数として置く．判別式を`Rational{BigInt}`で求め，`BigFloat`に変換して平方根をとる．精度を引数で変えられるようにすると，精度の検査に使える．
- 検査に使う係数を`test/helpers.jl`にまとめる．桁落ちする係数，重根，根が0，Kahanの例，根が1.5と1.5(1 + δ)の係数(δ = 10⁻⁴，10⁻⁸など)を含める．δによっては，係数を丸めた結果として実根がなくなる．
- `discriminant`は，`two_prod`でb²と4acを分解する．打ち消しが大きいかどうかの判定には，理論のノートの3節の条件を使う．
- `quadratic_roots`の符号の扱いには`copysign`を使う．q = 0になるのはどんな係数のときかを考える．
- `root_backward_error`と`root_condition_number`は，有理数で計算すると丸め誤差を考えずに済む．

### よくある間違い

- 小さい根を(−b + √d)/(2a)で求める．b² ≫ |4ac|の係数で桁落ちする．
- 判別式を`b^2 - 4a * c`で求める．根が近い係数で前進誤差が大きくなるが，後退誤差のテストだけでは見つからない．
- `sign(b)`を使う．b = 0のとき`sign(0.0)`は0なので，√dが消えてしまう．
- 参照解の`BigFloat`を，`Float64`の判別式から作る．判別式の誤差が参照解に入る．

## 1-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．
2. `discriminant`の最後で丸め誤差を加えるのをやめる(`return d`にする)と，自分のどのテストが失敗するか．後退誤差のテストは失敗するか．理由を理論のノートの6節で説明する(確かめたら元に戻す)．
3. 根の誤差を参照解で検査するテストと，解と係数の関係で検査するテストは，それぞれどんな間違いを見つけるか．片方だけでは見つからない間違いを挙げる．
4. 参照解の精度を256ビットから64ビットに下げると，何が起きるか．参照解の精度を検査するテストがない場合に何が困るか．
5. リファクタリングの前後で，テストの件数と結果はどうだったか．テストがない状態でリファクタリングすると，何が困るか．
6. 単体テストと結合テストは，それぞれ何を確かめているか．
7. 設計文書と実装を見比べ，食い違うところを直す．依存図の矢印，誤差仕様書の関数名・誤差界・テストファイルのパスが実装と一致しているかを確かめ，`mise run design iterations/iteration-1/exercise`が通るようにする．

## 1-7 発展課題

b = 10²⁰⁰のように係数が大きいと，b²がオーバーフローして`Inf`になる．
係数を2の冪で一斉に拡大縮小してから根を求めるように`quadratic_roots`を直す．係数の大きさによらず，正しい根を返すようにする．
2の冪による拡大縮小は丸め誤差を生まず，根も変わらない．

テストリスト，設計文書(誤差仕様書の前提，ADR)，テストファーストの実装の順に進める．
