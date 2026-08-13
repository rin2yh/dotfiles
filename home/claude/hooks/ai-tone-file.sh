#!/bin/sh
# PostToolUse フック。書き込まれた Markdown を textlint に当てて、指摘があれば止める。
# textlint が読めるのは Markdown だけなので、それ以外の拡張子は何もせず通す。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

command -v jq >/dev/null 2>&1 || exit 0
command -v textlint >/dev/null 2>&1 || exit 0
command -v mise >/dev/null 2>&1 || exit 0

file=$(jq -r '.tool_input.file_path // ""' 2>/dev/null)
case "$file" in
  *.md) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
# 場所が引けないときは検査を諦めて通す。ここで通さないと、ルールが 0 件のまま
# textlint が出す「No rules found」を指摘と誤認して、何を書いても止まり続ける。
prh=$(mise where npm:textlint-rule-prh 2>/dev/null)
preset=$(mise where npm:textlint-rule-preset-ja-technical-writing 2>/dev/null)
[ -d "$prh/lib/node_modules" ] && [ -d "$preset/lib/node_modules" ] || exit 0
NODE_PATH="$prh/lib/node_modules:$preset/lib/node_modules"
export NODE_PATH

cd "$DIR" 2>/dev/null || exit 0
report=$(textlint --config .textlintrc.json --format compact "$file")
[ -n "$report" ] || exit 0

{
  echo "$file に AI 文体の指摘がある。書き直してから次に進むこと。"
  echo "$report" | head -n 40
} >&2
exit 2
