# textlint-rule-preset-ja-no-ai-tone

LLM が書きがちな日本語の文体を検出する textlint プリセット。

`textlint-rule-preset-ja-technical-writing` が文の長さ・表記ゆれ・文法といった
**形式**を見るのに対して、こちらは「情報を運んでいない語」という**中身の薄さ**を見る。
両方を併用する前提で作ってある。

## 2 つのルール

プリセットは prh を 2 つのルール ID に分けて登録する。自動修正の可否が違うため。

| ルール ID | 辞書 | severity | `--fix` |
| --- | --- | --- | --- |
| `ja-no-ai-tone/ai-tone` | `dict/ai-tone.yml` | error | 当ててよい |
| `ja-no-ai-tone/ai-tone-review` | `dict/ai-tone-review.yml` | warning | 当ててはいけない |

`ai-tone-review` の `expected` は置換候補ではなく**書き直しの方針**を書いてある。
prh の報告は「マッチした文字列 => expected」の形で出るため、方針をそのまま指摘文として読ませられる。
その代わり `--fix` を当てると方針の文言が本文に埋め込まれるので、
自動修正は `ai-tone` だけを有効にした `.textlintrc.fix.json` 経由で行う。

```bash
npm run lint -- path/to/article.md   # 全部の指摘
npm run fix  -- path/to/article.md   # 機械的に直せるものだけ自動修正
npm test                             # 辞書の回帰テスト
```

## 辞書の書き方

`scope: chat` は prh が無視する独自キーで、Claude Code の Stop フック（会話出力の検査）の
対象に含めるかを示す。会話は文章より短く砕けているため、
文書向けの規則をそのまま当てると誤検出が増える。

`specs` は必ず書く。prh は `specs` が 1 件でも外れると辞書のロード自体を失敗させるため、
これがそのまま回帰テストになる。

### prh の正規表現の制約

踏むと辞書のロードが失敗するので先に知っておく。

- 正規表現リテラルに使えるフラグは `gimy` だけ。`/.../u` と書くと正規表現として認識されず、
  文字列リテラルとして丸ごとエスケープされる
- prh が内部で `u` フラグを常に付けるため、`\u{...}` とサロゲートペアが書けない。
  絵文字のような文字は実物を `patterns` に列挙する
- prh が見るのは Markdown の記法を取り除いた本文。`^#` のような記法依存の判定はできない
- 後方参照は `$1` 形式

## 生成物

`dict/generated/*.patterns` は `npm run gen` が辞書から生成する ripgrep 用のパターンで、
Claude Code の Stop フックが使う。textlint の起動には 1.5 〜 2 秒かかり、
毎ターン走るフックには重すぎるため、会話の検査だけは ripgrep で済ませている。

生成物はコミットする。フックが `npm install` 前でも動く必要があるため。
辞書とのずれは `npm test` が検出する。

## 切り出して公開する場合

このディレクトリはそのまま npm パッケージとして成立する（`package.json` の `files` に
`index.js` と `dict` を指定済み）。`scripts/` と `dict/generated/` は
dotfiles のフック用なので、公開するなら含めなくてよい。
