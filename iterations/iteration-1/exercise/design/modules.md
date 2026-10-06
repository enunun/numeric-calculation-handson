# モジュール依存図

`StableNumerics`を構成するモジュールと，その依存関係を示す．
矢印`A --> B`は，`A`が`B`の関数を使うことを表す．

```mermaid
flowchart LR
    StableNumerics --> ErrorBounds
    StableNumerics --> Summation
```

- `StableNumerics`は，`ErrorBounds`と`Summation`の関数を公開する．`StableNumerics`自身は計算をしない．
- `ErrorBounds`は，誤差解析の定数(単位丸めu，γₙ)と，誤差の測り方(相対誤差)を受け持つ．
- `Summation`は，総和の計算と総和の条件数を受け持つ．
- テストは，`ErrorBounds`の関数で許容誤差と実際の誤差を求める．
