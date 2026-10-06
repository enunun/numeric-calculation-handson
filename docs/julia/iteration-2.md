# Iteration 2：乱数，ブロードキャスト，テスト専用の依存

Iteration 2で初めて使うJuliaの文法と機能をまとめる．

## Random

標準ライブラリ`Random`は，乱数生成器と乱数の関数を提供する．
使う前に`using Random`と書く．

```julia
julia> using Random

julia> rng = Xoshiro(42); rand(rng, 3)
3-element Vector{Float64}:
 0.6293451231426089
 0.4503389405961936
 0.47740714343281776

julia> rng = Xoshiro(42); rand(rng, 3)
3-element Vector{Float64}:
 0.6293451231426089
 0.4503389405961936
 0.47740714343281776
```

- `Xoshiro(seed)`は，シードseedから乱数生成器を作る．同じシードからは同じ乱数列が得られる．
- `rand(rng, n)`は0以上1未満の一様乱数をn個，`randn(rng, n)`は標準正規分布の乱数をn個返す．
- `rand(rng, 2:5)`は2から5までの整数から1つを，`rand(rng, (-1, 1))`はタプルの要素から1つを選ぶ．
- `shuffle(rng, xs)`は，xsを並べ替えた新しいベクトルを返す．

```julia
julia> randn(Xoshiro(1), 2)
2-element Vector{Float64}:
 -0.07058313895389791
  0.5314767537831963

julia> rand(Xoshiro(1), 2:5)
2

julia> shuffle(Xoshiro(1), [1, 2, 3, 4])
4-element Vector{Int64}:
 4
 3
 1
 2
```

乱数生成器を引数`rng`で受け取る関数にしておくと，呼び出す側がシードを決められる．
テストでは，必ずシードを指定した乱数生成器を使う．

## ブロードキャスト

演算子や関数の前後に`.`を付けると，ベクトルの要素ごとに計算する．これをブロードキャストと呼ぶ．
スカラーとベクトルを混ぜると，スカラーはすべての要素に使われる．

```julia
julia> [1.0, 2.0] .+ 10.0
2-element Vector{Float64}:
 11.0
 12.0

julia> 2.0 .* [1.0, 2.0] .+ [0.5, 0.5]
2-element Vector{Float64}:
 2.5
 4.5

julia> round.([1.4, 2.6])
2-element Vector{Float64}:
 1.0
 3.0
```

`center .+ spread .* randn(rng, n)`は，n個の正規乱数をそれぞれspread倍してcenterを足したベクトルを作る．
Iteration 1の`Rational{BigInt}.((a, b, c, r))`も，関数`Rational{BigInt}`をタプルの要素ごとに適用するブロードキャストである．

## enumerate

`enumerate(xs)`は，番号と要素の組を順に返す．番号は1から始まる．

```julia
julia> for (k, x) in enumerate([10.0, 20.0])
           println(k, " ", x)
       end
1 10.0
2 20.0
```

Welfordの算法では，k番目のデータで平均の更新にkを使うので，`enumerate`で番号を受け取る．

## ジェネレータ式

`sum(式 for 変数 in 範囲)`のように，内包表記の角括弧を外した形をジェネレータ式と呼ぶ．
ベクトルを作らずに，値を1つずつ関数に渡す．

```julia
julia> sum(Rational{BigInt}(x)^2 for x in [1.0, 2.0])
5//1
```

## @testsetのfor形式

`@testset "名前 $(変数)" for 変数 in 範囲 ... end`と書くと，範囲の値ごとに別の`@testset`ができる．
名前に変数の値を入れておくと，失敗したときにどの値で失敗したかが分かる．

```julia
@testset "variance：厳密な性質 seed = $(seed)" for seed in SEEDS
    rng = Xoshiro(seed)
    # ...
end
```

失敗すると，次のように`@testset`の名前が表示される．

```text
variance：メタモルフィック関係 seed = 1: Test Failed at …/test/unit/moments_tests.jl:60
```

## テスト専用の依存を加える

`Random`はテストだけで使うので，パッケージ本体の依存(`[deps]`)ではなく，テスト専用の依存に加える．
`Project.toml`の`[extras]`に名前とUUIDを書き，`[targets]`の`test`に名前を加える．

```toml
[extras]
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Random", "Test"]
```

標準ライブラリのUUIDは，REPLで次のようにして調べられる．

```julia
julia> import Pkg

julia> Pkg.Types.stdlibs()
```

表示される辞書から，名前が`"Random"`の項目のUUIDを探す．
テスト専用の依存は，`Pkg.test`がテストを実行するときだけ読み込まれる．
REPLで`using Random`をするには，REPLの環境に`Random`があればよい(標準ライブラリは通常そのまま使える)．
