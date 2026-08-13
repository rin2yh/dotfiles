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

## `--fix` は当てない

辞書の後半にある規則は `expected` に**書き直しの方針**を書いてある。
prh の報告は「マッチした文字列 => expected」の形で出るので、方針をそのまま指摘文として読ませられる。
その代償として `textlint --fix` を当てると、本文が方針の文言に置き換わる。

自動修正は提供していない。`npx textlint --fix` を手で叩かないこと。

## 辞書の書き方

`home/claude/skills/ai-tone-dict/references/writing-rules.md` にある。
prh の正規表現には固有の制約があり、知らずに書くと辞書のロードが失敗する。
