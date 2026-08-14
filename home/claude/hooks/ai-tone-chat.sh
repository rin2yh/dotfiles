#!/bin/sh
# Stop フック。直前の応答本文を textlint に当てて、AI 文体の常套句があれば止める。
# 終了コード 2 で stderr に書くと、Claude はそれを理由として読んで応答し直す。

set -u

# 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
text=$(jq -r 'if .stop_hook_active then "" else .last_assistant_message // "" end')
[ -n "$text" ] || exit 0

report=$(printf '%s' "$text" | ~/.config/textlint/lint.sh --stdin --stdin-filename chat.md)
[ -n "$report" ] || exit 0

{
  echo "AI 文体の常套句が含まれている。削るか具体的な語に置き換えて応答し直すこと。"
  echo "$report" | head -n 40
} >&2
exit 2
