#!/bin/sh
# PostToolUse フック。書き込まれた Markdown を textlint に当てて、指摘があれば止める。

set -u

file=$(jq -r .tool_input.file_path)
case "$file" in
  *.md) ;;
  *) exit 0 ;;
esac

report=$(~/.config/textlint/lint.sh "$file")
[ -n "$report" ] || exit 0

{
  echo "$file に AI 文体の指摘がある。書き直してから次に進むこと。"
  echo "$report" | head -n 40
} >&2
exit 2
