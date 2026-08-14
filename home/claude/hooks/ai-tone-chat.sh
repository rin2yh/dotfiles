#!/bin/sh
# Stop フック。直前の応答本文を textlint に当てて、AI 文体の常套句があれば止める。
# 終了コード 2 で stderr に書くと、Claude はそれを理由として読んで応答し直す。
# jq・textlint・mise は dotfiles が用意する前提なので、存在確認はしない。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

input=$(cat)

# 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

text=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""')
[ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || exit 0

# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
NODE_PATH="$(mise where npm:textlint-rule-prh)/lib/node_modules"
NODE_PATH="$NODE_PATH:$(mise where npm:textlint-rule-preset-ja-technical-writing)/lib/node_modules"
export NODE_PATH

cd "$DIR" || exit 0
report=$(printf '%s' "$text" | textlint --config .textlintrc.json --format compact --stdin --stdin-filename chat.md)
[ -n "$report" ] || exit 0

{
  echo "AI 文体の常套句が含まれている。削るか具体的な語に置き換えて応答し直すこと。"
  echo "$report" | head -n 40
} >&2
exit 2
