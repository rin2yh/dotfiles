# textlint-rule-preset-ja-no-ai-tone

LLM が書きがちな日本語の文体を検出する textlint プリセット。

`textlint-rule-preset-ja-technical-writing` が文の長さ・表記ゆれ・文法といった
**形式**を見るのに対して、こちらは「情報を運んでいない語」という**中身の薄さ**を見る。
両方を併用する前提で作ってある。

## 2 つのルール

prh を 2 つのルール ID に分けて登録する。自動修正の可否が違うため。

| ルール ID | 辞書 | severity | `--fix` |
| --- | --- | --- | --- |
| `ja-no-ai-tone/ai-tone` | `dict/ai-tone.yml` | error | 当たる |
| `ja-no-ai-tone/ai-tone-review` | `dict/ai-tone-review.yml` | warning | 当たらない |

`ai-tone-review` の `expected` は置換候補ではなく**書き直しの方針**を書いてある。
prh の報告は「マッチした文字列 => expected」の形で出るため、方針をそのまま指摘文として読ませられる。
`--fix` を当てると方針の文言が本文に埋め込まれてしまうので、
このルールは prh の linter だけを登録して fixer を渡していない。自動修正が構造的に届かない。

`dict/fix-safety.txt` は `ai-tone.yml` の規則を全部当てても変わってはいけない文の一覧。
`specs` はその規則の中しか検査しないため、別の規則を足した結果として壊れる事故は防げない。

## 使い方

```bash
npx textlint --config ../.textlintrc.json path/to/article.md
npx textlint --fix --config ../.textlintrc.json path/to/article.md
```

辞書を更新したら、そのまま textlint を 1 回通す。prh は `specs` が 1 件でも外れると
ロードに失敗するので、それだけで書いたパターンが実際に当たるかを確かめられる。

辞書の書き方と prh の制約は `home/claude/skills/ai-tone-dict/references/writing-rules.md` にある。

## 切り出して公開する場合

このディレクトリはそのまま npm パッケージとして成立する（`package.json` の `files` に
`index.js` と `dict` を指定済み）。`fix-safety.txt` は dotfiles の検査用なので、公開するなら外してよい。
