# 数値計算の品質保証ハンズオン

浮動小数点数の計算には，必ず誤差が入る．
では，数値計算のプログラムが「正しい」とは，どういうことだろうか．
このハンズオンでは，Juliaのライブラリ`StableNumerics`をテスト駆動開発で少しずつ育てながら，この問いに答える方法を学ぶ．

```julia
julia> using StableNumerics

julia> xs = [1e16, 1.0, -1e16];

julia> naive_sum(xs), compensated_sum(xs)
(0.0, 1.0)
```

素朴に書くと壊れる計算を，誤差の理論で説明し，安定なアルゴリズムに置き換え，その精度の主張をテストで保証する．
これを総和，二次方程式，分散，連立1次方程式，最小二乗法，指数関数の順に繰り返す．

## 学ぶこと

- 丸め誤差・打ち切り誤差・条件数の理論と，それに基づくテストの許容誤差(絶対・相対・ULP)の決め方
- 厳密な答えが分からない計算を，性質・不変量・メタモルフィック関係で検査する方法
- アルゴリズムの安定性を後退誤差で評価し，不安定な実装をテストで見つける方法
- テストリスト → 設計文書 → テストファーストの実装 → 設計レビューという開発の進め方

## 前提

- 何らかのプログラミング言語で，関数とテストを書いたことがある．
- 大学初年級の微積分(テイラー展開)と線形代数(行列とベクトル，ノルム)を知っている．
- Juliaと数値解析の経験は問わない．どちらもIterationごとのノートで説明する．

## 環境の準備

このリポジトリは，VS CodeのDev Containerで使う．
Juliaと，教材の検査に使うツールは，Dev Containerにすべて入っている．

1. DockerとVS Code，VS Codeの拡張機能Dev Containersを入れる．
2. このリポジトリをVS Codeで開き，コマンドパレットで「Dev Containers: Reopen in Container」を実行する．初回はコンテナの構築と`mise run setup`が走る．
3. VS Codeのターミナルで次を実行し，すべての検査が通ることを確かめる．

```sh
mise run check
```

`mise tasks`で，使えるタスクの一覧が表示される．

## 進め方

ハンズオンは6つのIteration(0〜5)からなる．
どのIterationも，`iterations/iteration-N/exercise/`の`README.md`と`docs/iteration-N.md`の手順に従って進める．

1. 要件を読み，テストリスト(`TESTLIST.md`)を書く．
2. 設計文書(`design/`)を更新する．
3. テストリストの項目を1つずつ，Red → Green → Refactorで実装する．
4. 設計文書と実装を見比べ，食い違いを直す．

終わったら，同じIterationの`solution/`と見比べる．
`solution/docs/iteration-N.md`には，各手順の解説がある．
次のIterationの`exercise/`は，前のIterationの`solution/`と同じコードから始まる．

## Iteration一覧

| Iteration | 作る機能 | 品質保証の主題 |
| --- | --- | --- |
| [0](iterations/iteration-0/exercise/README.md) | 総和(素朴・補償付き) | 厳密な参照解，誤差界から導く許容誤差 |
| [1](iterations/iteration-1/exercise/README.md) | 二次方程式の実根 | 後退誤差，高精度の参照解，特殊値 |
| [2](iterations/iteration-2/exercise/README.md) | 平均と分散 | 性質ベーステスト，メタモルフィックテスト |
| [3](iterations/iteration-3/exercise/README.md) | LU分解による連立1次方程式 | 残差による後退誤差の検査 |
| [4](iterations/iteration-4/exercise/README.md) | QR分解による最小二乗法 | 製造解，リファクタリングの安全網 |
| 5 | 指数関数 | ULP誤差，差分テスト，局所的な全数検査 |

各Iterationの要件と学ぶことは，[ロードマップ](docs/ROADMAP.md)にある．

## ガイドとノート

| 文書 | 内容 |
| --- | --- |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Iterationごとの要件，使用例，学ぶこと |
| [docs/qa.md](docs/qa.md) | 数値計算の品質保証の考え方(このコースの全体像) |
| [docs/tdd.md](docs/tdd.md) | テスト駆動開発とテストリストの書き方 |
| [docs/design.md](docs/design.md) | 設計文書(依存図，誤差仕様書，ADR)の書き方 |
| [docs/theory/](docs/theory/README.md) | Iterationごとの数値計算の理論 |
| [docs/julia/](docs/julia/README.md) | Iterationごとに初めて使うJuliaの文法と機能 |

## リポジトリの構成

```text
docs/                   ガイドとノート
iterations/iteration-N/
  exercise/             学習者が作業するパッケージ
  solution/             完成したパッケージと模範解答
scripts/                設計文書の検査と，すべてのテストの実行
.devcontainer/          Dev Container
mise.toml               ツールの版とタスク
```

## よく使うコマンド

| 目的 | コマンド |
| --- | --- |
| パッケージを有効にしてREPLを起動する | `julia --project=iterations/iteration-0/exercise` |
| パッケージのテストを実行する | REPLのPkgモード(`]`)で`test` |
| 設計文書を検査する | `mise run design iterations/iteration-0/exercise` |
| すべての検査を実行する | `mise run check` |

## ライセンス

[LICENSE](LICENSE)を参照．
