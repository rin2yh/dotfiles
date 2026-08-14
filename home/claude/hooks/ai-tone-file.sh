#!/bin/sh
# PostToolUse フック。書き込まれた Markdown を textlint に当てて、指摘があれば止める。
# textlint が読めるのは Markdown だけなので、それ以外の拡張子は何もせず通す。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

file=$(jq -r '.tool_input.file_path // ""')
case "$file" in
  *.md) ;;
  *) exit 0 ;;
esac

# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
NODE_PATH="$(mise where npm:textlint-rule-prh)/lib/node_modules"
NODE_PATH="$NODE_PATH:$(mise where npm:textlint-rule-preset-ja-technical-writing)/lib/node_modules"
export NODE_PATH

report=$(textlint --config "$DIR/.textlintrc.json" --format compact "$file")
[ -n "$report" ] || exit 0

{
  echo "$file に AI 文体の指摘がある。書き直してから次に進むこと。"
  echo "$report" | head -n 40
} >&2
exit 2
