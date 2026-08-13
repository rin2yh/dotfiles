#!/bin/sh
# PreToolUse フック。GitHub へ投稿しようとしているタイトルと本文を textlint に当てて、
# 指摘があれば投稿の前に止める。settings.json 側で mcp__github__* に絞ってある。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

command -v jq >/dev/null 2>&1 || exit 0
command -v textlint >/dev/null 2>&1 || exit 0
command -v mise >/dev/null 2>&1 || exit 0

input=$(cat)
title=$(printf '%s' "$input" | jq -r '.tool_input.title // ""' 2>/dev/null)
body=$(printf '%s' "$input" | jq -r '.tool_input.body // ""' 2>/dev/null)
[ -n "$(printf '%s%s' "$title" "$body" | tr -d '[:space:]')" ] || exit 0

# タイトルは見出しとして渡す。裸の一行にすると、文末が「。」で終わっていないと
# 毎回言われて、投稿のたびに必ず止まることになる。
text=$(printf '# %s\n\n%s' "$title" "$body")

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
report=$(printf '%s' "$text" | textlint --config .textlintrc.json --format compact --stdin --stdin-filename post.md)
[ -n "$report" ] || exit 0

{
  echo "投稿しようとしている本文に AI 文体の指摘がある。書き直してから投稿すること。"
  echo "$report" | head -n 40
} >&2
exit 2
