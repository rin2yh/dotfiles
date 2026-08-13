#!/bin/sh
# Stop フック。直前の応答本文を textlint に当てて、AI 文体の常套句があれば止める。
# 終了コード 2 で stderr に書くと、Claude はそれを理由として読んで応答し直す。
# フックのせいで会話が止まるのが一番困るので、想定外は何も言わずに通す。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"

command -v jq >/dev/null 2>&1 || exit 0
command -v textlint >/dev/null 2>&1 || exit 0
command -v mise >/dev/null 2>&1 || exit 0

input=$(cat)

# 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

text=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""' 2>/dev/null)
[ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || exit 0

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
report=$(printf '%s' "$text" | textlint --config .textlintrc.json --format compact --stdin --stdin-filename chat.md)
[ -n "$report" ] || exit 0

{
  echo "AI 文体の常套句が含まれている。削るか具体的な語に置き換えて応答し直すこと。"
  echo "$report" | head -n 40
} >&2
exit 2
