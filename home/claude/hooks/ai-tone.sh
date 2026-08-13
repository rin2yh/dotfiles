#!/bin/sh
# Claude Code のフックが渡す JSON から検査対象を取り出し、textlint に流す。
# 指摘があれば終了コード 2 で stderr に理由を返す。3 つの発火点のいずれでも
# 「stderr を理由として Claude に渡し、その操作を止める」と決まっているので、
# 発火点ごとに違う JSON を組み立てる必要がない。
#
#   Stop         直前の応答本文
#   PostToolUse  書き込まれた Markdown ファイル
#   PreToolUse   GitHub へ投稿しようとしているタイトルと本文
#
# フックのせいで会話が止まるのが一番困るので、想定外は何も言わずに通す。

set -u

DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"
MAX_LINES=40

command -v jq >/dev/null 2>&1 || exit 0
command -v npx >/dev/null 2>&1 || exit 0

# .textlintrc.json の rulePaths が辞書を相対パスで指すので、必ずそこで動かす。
cd "$DIR" 2>/dev/null || exit 0

input=$(cat)
get() { printf '%s' "$input" | jq -r "$1 // \"\"" 2>/dev/null; }

event=$(get .hook_event_name)
tool=$(get .tool_name)
file=""
text=""

case "$event" in
  Stop | SubagentStop)
    # 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
    [ "$(get .stop_hook_active)" = "true" ] && exit 0
    text=$(get .last_assistant_message)
    reason="AI 文体の常套句が含まれている。削るか具体的な語に置き換えて応答し直すこと。"
    ;;
  PreToolUse)
    # GitHub へ投稿する MCP ツールだけ。PR の本文・タイトル、レビュー、コメント。
    case "$tool" in
      mcp__github__*pull_request* | mcp__github__*issue* | mcp__github__*comment* | mcp__github__*review*) ;;
      *) exit 0 ;;
    esac
    # タイトルは見出しとして渡す。裸の一行にすると、文末が「。」で終わっていないと
    # 毎回言われて、投稿のたびに必ず止まることになる。
    text=$(printf '# %s\n\n%s' "$(get .tool_input.title)" "$(get .tool_input.body)")
    reason="投稿しようとしている本文に AI 文体の指摘がある。書き直してから投稿すること。"
    ;;
  PostToolUse)
    case "$tool" in
      Write | Edit | MultiEdit) ;;
      *) exit 0 ;;
    esac
    # textlint が読めるのは Markdown だけ。それ以外を渡すとパーサが無いと言って落ちる。
    file=$(get .tool_input.file_path)
    case "$file" in
      *.md) ;;
      *) exit 0 ;;
    esac
    reason="$file に AI 文体の指摘がある。書き直してから次に進むこと。"
    ;;
  *) exit 0 ;;
esac

# textlint は npx がその場で解決する。リポジトリに package.json も node_modules も置かない。
lint() {
  npx --yes \
    --package textlint \
    --package textlint-rule-prh \
    --package textlint-rule-preset-ja-technical-writing \
    -- textlint --config .textlintrc.json --format compact "$@"
}

if [ -n "$file" ]; then
  report=$(lint "$file")
else
  [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || exit 0
  report=$(printf '%s' "$text" | lint --stdin --stdin-filename chat.md)
fi

[ -n "$report" ] || exit 0

{
  echo "$reason"
  echo "$report" | head -n "$MAX_LINES"
} >&2
exit 2
