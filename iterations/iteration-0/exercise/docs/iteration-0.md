# Iteration 0の手順：浮動小数点数と総和

このIterationでは，浮動小数点数の総和を素朴な方法と補償付きの方法で計算する関数を作る．
誤差の上界を理論で導き，それをテストの許容誤差にする．
作業はすべて`iterations/iteration-0/exercise/`で行う．

## 0-1 準備

1. VS Codeのターミナルで，演習のパッケージのディレクトリに移動し，パッケージを有効にしてREPLを起動する．

   ```sh
   cd iterations/iteration-0/exercise
   julia --project=.
   ```

2. `]`でPkgモードに入り，`test`を実行する．テストはまだ1つもないので，次のように0件で終わる．

   ```text
   Test Summary:  | Total  Time
   StableNumerics |     0  0.0s
        Testing StableNumerics tests passed
   ```

3. Backspaceで`julia>`に戻り，パッケージを読み込んで関数を呼んでみる．関数はまだスタブなので，例外が起きる．

   ```julia
   julia> using StableNumerics

   julia> naive_sum([1.0, 2.0])
   ERROR: naive_sumは未実装
   ```

4. 別のターミナルで，リポジトリのルートから設計文書を検査する．設計文書はまだ書かれていない．このため，依存図がないことと，誤差仕様書の表に載っていない公開関数の名前が報告される．

   ```sh
   mise run design iterations/iteration-0/exercise
   ```

5. `src/`の3つのファイルを読み，どの関数を作るのかを確かめる．

## 0-2 文法と概念

[Juliaのノート](../../../../docs/julia/iteration-0.md)と[理論のノート](../../../../docs/theory/iteration-0.md)を読み，REPLで次の課題を解く．

1. `eps(1.0)`，`eps(1e16)`，`eps(1e-300)`を求め，ULPが値の大きさに比例して変わることを確かめる．
2. `1e16 + 1.0 == 1e16`が`true`になる理由を，`eps(1e16)`を使って説明する．
3. `Rational{BigInt}(0.1)`の分母が2の冪であることを確かめる．`Rational{BigInt}(0.1) - 1 // 10`を計算し，0.1の表現誤差の相対誤差がu = 2⁻⁵³以下であることを確かめる．
4. `[1e16, 1.0, -1e16]`の総和の条件数κを手で計算し，素朴な総和の誤差界γₙ₋₁·κがいくつになるかを見積もる．
5. `@test 0.1 + 0.2 == 0.3`，`@test 0.1 + 0.2 ≈ 0.3`，`@test 1e-20 ≈ 0.0`を実行し，結果の違いを説明する．
6. 次の関数`f`は`Float64`のベクトルでも`Float32`のベクトルでも呼べる．`f([1.0, 2.0])`と`f([1.0f0, 2.0f0])`の結果の型を確かめる．

   ```julia
   f(xs::AbstractVector{T}) where {T<:AbstractFloat} = zero(T) + xs[1]
   ```

## 0-3 テストリスト

次の要件と使用例を読み，`TESTLIST.md`に確かめる振る舞いを書き出す．

### 要件

- 浮動小数点数のベクトルの総和を，素朴な方法(先頭から順に足す)と補償付きの方法で計算できる．
- 2つの浮動小数点数の和を，丸めた和と丸め誤差の組に分解できる．この分解に誤差はない．
- 総和の条件数を計算できる．
- 単位丸めと，誤差解析に使う定数γₙを計算できる．
- 計算結果の相対誤差を，厳密な値(有理数)と比べて求められる．

### 使用例

```julia
julia> naive_sum([1e16, 1.0, -1e16]), compensated_sum([1e16, 1.0, -1e16])
(0.0, 1.0)

julia> two_sum(1e16, 1.0)
(1.0e16, 1.0)

julia> sum_condition_number([1e16, 1.0, -1e16])
2.0e16

julia> unit_roundoff(Float64), gamma(10, Float64)
(1.1102230246251565e-16, 1.1102230246251577e-15)

julia> relative_error(naive_sum(fill(0.1, 10)), 10 * Rational{BigInt}(0.1))
1.6653345369377348e-16
```

### 作るもの

- `ErrorBounds`
  - `unit_roundoff(::Type{T}) where {T<:AbstractFloat}`：単位丸めu = eps(T)/2．
  - `gamma(n::Integer, ::Type{T}) where {T<:AbstractFloat}`：γₙ = nu/(1 − nu)．nu ≥ 1なら`ArgumentError`．
  - `relative_error(computed::AbstractFloat, exact::Rational{BigInt})`：相対誤差を有理数で厳密に求め，`Float64`で返す．正しい値が0なら，計算値も0のとき0.0，そうでなければ`Inf`．
- `Summation`
  - `two_sum(a::T, b::T) where {T<:AbstractFloat}`：`(s, e)`を返す．s = fl(a + b)，a + b = s + e．
  - `naive_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}`
  - `compensated_sum(xs::AbstractVector{T}) where {T<:AbstractFloat}`：Ogita–Rump–OishiのSum2．
  - `sum_condition_number(xs::AbstractVector{T}) where {T<:AbstractFloat}`：Σ|xᵢ|/|Σxᵢ|．総和が0なら`Inf`．

### 考えること

- 各項目は，期待値を`==`で厳密に比べられるか，許容誤差が要るか．許容誤差が要るなら，その値は理論のノートのどの誤差界から決まるか．
- 参照解(正しい答え)をどう用意するか．
- 誤差界の検査には，どんなデータを使うか．条件数が1のデータだけで十分か．
- どの項目が単体テストで，どの項目が結合テストか．結合テストでは，ライブラリの利用者が公開APIをどう組み合わせて使うかを考える．
- 境界の入力(空のベクトル，和が0になるデータ)で何が起きるべきか．

[テスト駆動開発のガイド](../../../../docs/tdd.md)の「テストリスト」も参照する．

## 0-4 設計文書

まず[設計文書のガイド](../../../../docs/design.md)を読む．
次に，`design/`の3つの文書を書く．各ファイルのコメントに，書く内容が説明されている．

- `design/modules.md`：`src/`には3つのモジュールがある．どのモジュールが，どのモジュールを`using`するか．`Summation`は`ErrorBounds`を使うか．
- `design/error-spec.md`：`StableNumerics`が公開する7つの関数すべてに行を書く．
  - `naive_sum`と`compensated_sum`の誤差界は，理論のノートの6節と8節にある．
  - `two_sum`は「誤差が0」を主張する関数である．許容誤差はいくつになるか．
  - `sum_condition_number`は，分子と分母をどの関数で計算するかで誤差界が変わる．分子と分母の誤差がどう積み重なるかを考える．
- `design/adr/0001-compensated-summation.md`：補償付き総和の方式として何を選ぶか．Kahanの方法，対ごとの総和(pairwise summation)，有理数による計算と比べて理由を書く．

書いたら，リポジトリのルートで設計文書を検査する．
誤差仕様書の「検証するテスト」に書いたテストファイルはまだないので，その報告は0-5で解消する．

```sh
mise run design iterations/iteration-0/exercise
```

## 0-5 テストファーストの実装

`TESTLIST.md`の項目を上から1つずつ，Red → Green → Refactorで実装する．
各項目で，テストを書いたらまず実行し，期待した理由で失敗することを確かめてから実装する．

### テストファイルの登録

テストファイルは，`test/runtests.jl`の対応するグループの中に`include`で登録する．
例えば`ErrorBounds`の単体テストは，`test/unit/error_bounds_tests.jl`を作り，次のように登録する．

```julia
    if "unit" in GROUPS
        @testset "unit" begin
            include("unit/error_bounds_tests.jl")
        end
    end
```

単体テストのファイルは，先頭でテストするモジュールを読み込む．

```julia
using StableNumerics.ErrorBounds

@testset "ErrorBounds" begin
    # ...
end
```

テストを登録したら，Pkgモードの`test`で実行する．

### 参照解とテストデータ

- 浮動小数点数のベクトルの厳密な総和は，各要素を`Rational{BigInt}`に変換して足せば求まる．
- 単体テストと結合テストの両方で使う参照解やテストデータは，`test/helpers.jl`に書き，`test/runtests.jl`で(グループより前に)`include`する．
- 誤差界の検査に使うデータは，名前とベクトルのペアのベクトルにすると，`for (name, xs) in データ`で繰り返せる．条件数が1のデータから10¹⁶程度のデータまでを含める．

### ErrorBounds

- `eps(T)`を使う．
- `gamma`で例外を投げるには`throw(ArgumentError("説明"))`を使う．
- `relative_error`は，`computed`を`Rational{BigInt}`に変換してから引き算する．`Float64`のまま引き算すると，その引き算で丸め誤差が入る．

### Summation

- `two_sum`は理論のノートの7節の6回の演算で書ける．テストでは，a + bとs + eを有理数に直して`==`で比べる．
- `naive_sum`の和の初期値は`zero(T)`にする．`0.0`と書くと，`Float32`のベクトルでも`Float64`を返してしまう．
- `compensated_sum`は，丸め誤差を足し込む変数を和とは別に用意し，最後に足す．
- `sum_condition_number`の分母には，どちらの総和を使うべきか．分母に誤差が大きいと何が起きるかを考える．

### よくある間違い

- 許容誤差に根拠のない数値(`1e-10`など)を使う．許容誤差は，誤差仕様書に書いた誤差界から計算する．
- Kahanの補償付き総和を書く．補正をすぐ次の加数に足し込む方法では，`[1e16, 1.0, -1e16]`で0.0になる．
- 文字列の補間で`"$nの値"`のように書く．日本語の直前では`$(n)`と書く．

## 0-6 振り返り

1. 自分の`TESTLIST.md`と，`solution/TESTLIST.md`を見比べる．自分のリストにない項目はあったか．それはどんな間違いを見つけるための項目か．
2. `compensated_sum`の最後で`return s + c`を`return s`に書き換えると，自分のどのテストが失敗するか．実際に書き換えて確かめる(確かめたら元に戻す)．`rtol = 1e-8`で比べるテストだったら，失敗しただろうか．
3. 誤差界の検査に，条件数が1のデータしか使っていなかったとする．どんな間違った実装が見逃されるか．
4. 単体テストと結合テストは，それぞれ何を確かめているか．結合テストがなかったら，どんな問題を見逃すか．
5. 誤差界は最悪の場合の上界で，実際の誤差はたいていずっと小さい．許容誤差を「実際の誤差の10倍」のように決める方法と比べて，誤差界を使う利点と欠点は何か．
6. 設計文書と実装を見比べ，食い違うところを直す．依存図の矢印，誤差仕様書の関数名・誤差界・テストファイルのパスが実装と一致しているかを確かめ，`mise run design iterations/iteration-0/exercise`が通るようにする．

## 0-7 発展課題

対ごとの総和(pairwise summation)`pairwise_sum(xs)`を`Summation`に加える．
ベクトルを半分に分けてそれぞれの和を再帰的に求め，最後に足す．
相対誤差の上界はγ⌈log₂n⌉·κである．

テストリスト，設計文書(依存図，誤差仕様書，ADR)，テストファーストの実装の順に進める．
