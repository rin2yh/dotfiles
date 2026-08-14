#!/bin/sh
# PreToolUse フック。GitHub へ投稿しようとしているタイトルと本文を textlint に当てて、
# 指摘があれば投稿の前に止める。
# settings.json の matcher は mcp__github__* 全体なので、読み取り系のツールも入ってくる。
# それらは title も body も持たないため、下の空判定がそのまま振り分けになる。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

input=$(cat)
title=$(printf '%s' "$input" | jq -r '.tool_input.title // ""')
body=$(printf '%s' "$input" | jq -r '.tool_input.body // ""')
[ -n "$title$body" ] || exit 0

# タイトルは見出しとして渡す。裸の一行にすると、文末が「。」で終わっていないと
# 毎回言われて、投稿のたびに必ず止まることになる。
text=$(printf '# %s\n\n%s' "$title" "$body")

# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
NODE_PATH="$(mise where npm:textlint-rule-prh)/lib/node_modules"
NODE_PATH="$NODE_PATH:$(mise where npm:textlint-rule-preset-ja-technical-writing)/lib/node_modules"
export NODE_PATH

report=$(printf '%s' "$text" | textlint --config "$DIR/.textlintrc.json" --format compact --stdin --stdin-filename post.md)
[ -n "$report" ] || exit 0

{
  echo "投稿しようとしている本文に AI 文体の指摘がある。書き直してから投稿すること。"
  echo "$report" | head -n 40
} >&2
exit 2
