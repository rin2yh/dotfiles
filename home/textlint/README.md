# AI っぽい日本語を検出する textlint 辞書

`preset-ja-technical-writing` が文の長さ・表記ゆれ・文法という**形式**を見るのに対して、
こちらは「情報を運んでいない語」という**中身の薄さ**を見る。両方を併用する前提で作ってある。

## 使い方

インストールは要らない。`npx` が必要なパッケージをその場で取ってくる。

```bash
ai-tone lint <file>    # textlint を呼ぶ。汎用プリセットの検査も含む
ai-tone fix  <file>    # 機械的に直せる指摘だけを自動修正する
ai-tone scan <file>    # 辞書だけを当てる。textlint を経由しないので速い
ai-tone check          # 辞書の回帰テスト
```

`package.json` と `node_modules` は置いていない。lock ファイルが差分の 76% を占めていたので、
バージョンを固定する代わりに毎回解決させている。

## 2 つの辞書

| 辞書 | 中身 | `--fix` |
| --- | --- | --- |
| `dict/ai-tone.yml` | 機械的に置換して意味が変わらない規則 | 当ててよい |
| `dict/ai-tone-review.yml` | 人間の判断が要る規則。`expected` に書き直しの方針を書く | 当ててはいけない |

後者の `expected` は置換候補ではなく方針なので、`--fix` を当てると本文に埋め込まれる。
自動修正は `ai-tone.yml` だけを読む `.textlintrc.fix.json` 経由で行う。

## `dict/fix-safety.txt`

`ai-tone.yml` を当てても変わってはいけない文の一覧。`specs` はその規則の中しか検査しないので、
別の規則を足した結果として壊れる事故を防げない。壊れる形を見つけたら、直すより先にここへ 1 行足す。

## 辞書の書き方

`home/claude/skills/ai-tone-dict/references/writing-rules.md` にある。
prh の正規表現には固有の制約があり、知らずに書くと辞書のロードが失敗する。
