# Juliaのノート

各Iterationで初めて使うJuliaの文法と機能をまとめる．

| Iteration | ノート | 主な内容 |
| --- | --- | --- |
| 0 | [Juliaの基本，パッケージ，テスト](iteration-0.md) | REPLとPkg，モジュール，数値の型，有理数，関数と型パラメータ，タプル，条件式と短絡評価，例外，内包表記，`Test` |
| 1 | [fma，nothing，BigFloat，多重ディスパッチ](iteration-1.md) | `fma`・`copysign`・`isfinite`・`minmax`，`nothing`と`Union`，`BigFloat`と`setprecision`，doブロック，ドット呼び出し，多重ディスパッチ，テストのグループの選択 |
| 2 | [乱数，ブロードキャスト，テスト専用の依存](iteration-2.md) | `Random`と`Xoshiro`，`rand`・`randn`・`shuffle`，ブロードキャスト，`enumerate`，ジェネレータ式，`@testset`のfor形式，`[extras]`と`[targets]` |
| 3 | [構造体，行列，LinearAlgebra](iteration-3.md) | `struct`とパラメータ型，キーワード引数，行列の添字，コピーと`!`の命名規約，`LinearAlgebra`の関数，パッケージの依存の追加，`argmax` |
| 4 | [転置，外積，部分行列の更新](iteration-4.md) | `transpose`と`'`，外積，`.-=`による部分行列の更新，`Matrix{T}(I, m, n)`，特定のテストファイルの実行 |
| 5 | [浮動小数点数の操作](iteration-5.md) | `ldexp`・`exponent`・`significand`，`round(Int, x)`，`evalpoly`，`nextfloat`による列挙，`bitstring`と`reinterpret`，テストのグループを分ける |
| 6 | [関数を渡す関数と型に依存しない関数](iteration-6.md) | 高階関数，匿名関数，型注釈のない関数と`BigFloat`，定数の型，`2^p`と`log2` |
