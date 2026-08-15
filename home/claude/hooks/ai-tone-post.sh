#!/bin/sh
# PreToolUse フック。GitHub へ投稿しようとしているタイトルと本文を textlint に当てて、
# 指摘があれば投稿の前に止める。
# settings.json の matcher は mcp__github__* 全体なので、読み取り系のツールも入ってくる。
# それらは title も body も持たないため、下の空判定がそのまま振り分けになる。
#
# タイトルは見出しとして渡す。裸の一行にすると、文末が「。」で終わっていないと
# 毎回言われて、投稿のたびに必ず止まることになる。

set -u

text=$(jq -r '(.tool_input.title // "") as $t | (.tool_input.body // "") as $b
              | if $t == "" and $b == "" then "" else "# \($t)\n\n\($b)" end')
[ -n "$text" ] || exit 0

report=$(printf '%s' "$text" | ~/.config/textlint/lint.sh --stdin --stdin-filename post.md)
[ -n "$report" ] || exit 0

{
  echo "投稿しようとしている本文に AI 文体の指摘がある。書き直してから投稿すること。"
  echo "$report" | head -n 40
} >&2
exit 2
