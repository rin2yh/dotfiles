#!/usr/bin/env bash
# AI っぽい日本語表現を検出する Claude Code フック。Stop / PostToolUse / PreToolUse を受ける。
#
# 発火点ごとに手段を変えている理由:
#   Stop        … 毎ターン走るので速度が要る。生成済みパターンを ripgrep で当てる（数 ms）。
#                 会話は短く砕けているため誤検出しやすく、既定は警告のみ。
#   PostToolUse … Markdown やコメントを書いた直後だけ走る。頻度が低いので textlint 本体を使い、
#                 preset-ja-technical-writing の検査も含めて既定でブロックする。
#   PreToolUse  … PR の本文・レビュー・コミットメッセージのように、
#                 リポジトリに残らないので他のどの経路でも拾えない文章を投稿の直前で止める。
#                 「書いたら検査する」を人間の記憶に任せると必ず飛ばすため、送信口に置いた。
#
# 強度は環境変数で変えられる。記事を書くセッションだけ会話も止めたい、
# といった切り替えを設定ファイルの編集なしで行えるようにしてある。
#   CLAUDE_AI_TONE_CHAT=off|warn|block   （既定: warn）
#   CLAUDE_AI_TONE_FILE=off|warn|block   （既定: block）
#   CLAUDE_AI_TONE_POST=off|warn|block   （既定: block）
#   CLAUDE_AI_TONE_DIR                   （既定は ~/workspace/dotfiles/home/textlint）

set -uo pipefail

TEXTLINT_DIR="${CLAUDE_AI_TONE_DIR:-$HOME/workspace/dotfiles/home/textlint}"
PATTERN_DIR="$TEXTLINT_DIR/preset-ja-no-ai-tone/dict/generated"
CHAT_MODE="${CLAUDE_AI_TONE_CHAT:-warn}"
FILE_MODE="${CLAUDE_AI_TONE_FILE:-block}"
POST_MODE="${CLAUDE_AI_TONE_POST:-block}"

# 依存が無い環境（別マシン、初回セットアップ前）では黙って通す。
# フックのせいで会話が止まるのは最悪なので、疑わしいときは何もしない。
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
event=$(jq -r '.hook_event_name // ""' <<<"$payload")

emit_json() { printf '%s\n' "$1"; exit 0; }

# --------------------------------------------------------------------
# Stop: 直前の応答本文を検査する
# --------------------------------------------------------------------
check_chat() {
  [ "$CHAT_MODE" = "off" ] && exit 0
  [ -f "$PATTERN_DIR/chat.patterns" ] || exit 0
  command -v rg >/dev/null 2>&1 || exit 0

  # ブロック後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
  [ "$(jq -r '.stop_hook_active // false' <<<"$payload")" = "true" ] && exit 0

  local message
  message=$(jq -r '.last_assistant_message // ""' <<<"$payload")
  [ -z "$message" ] && exit 0

  # コード中の語は文体の問題ではないので、フェンスドブロックとインラインコードを落とす。
  # 引用符で囲まれた指摘（このフック自身が挙げた語を復唱する場合など）も同様に外れる。
  local prose
  prose=$(awk '/^[[:space:]]*```/ { fence = !fence; next } !fence' <<<"$message" \
    | sed 's/`[^`]*`//g')

  local hits
  hits=$(rg --only-matching --no-filename --no-line-number \
    --file "$PATTERN_DIR/chat.patterns" <<<"$prose" 2>/dev/null | sort -u | head -n 12)
  [ -z "$hits" ] && exit 0

  # paste -d は区切り文字を 1 バイトしか受け取らず、読点を渡すと壊れたバイトが混じる。
  local list
  list=$(awk 'NR > 1 { printf "、" } { printf "%s", $0 } END { print "" }' <<<"$hits")

  if [ "$CHAT_MODE" = "block" ]; then
    emit_json "$(jq -nc --arg list "$list" '{
      decision: "block",
      reason: ("直前の応答に AI 文体の常套句が含まれている: " + $list +
               "。これらは削るか、具体的な語に置き換えて応答し直すこと。" +
               "語を消して意味が変わらないなら、その語は不要。")
    }')"
  fi

  emit_json "$(jq -nc --arg list "$list" '{
    systemMessage: ("AI っぽい語: " + $list)
  }')"
}

# --------------------------------------------------------------------
# PostToolUse: 書き込まれた Markdown を textlint にかける
# --------------------------------------------------------------------
check_file() {
  [ "$FILE_MODE" = "off" ] && exit 0

  local tool file
  tool=$(jq -r '.tool_name // ""' <<<"$payload")
  case "$tool" in
    Write | Edit | MultiEdit | NotebookEdit) ;;
    *) exit 0 ;;
  esac

  file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$payload")
  [ -f "$file" ] || exit 0

  # 依存が入っていなければ何もしない。セットアップは `npm install` を一度実行するだけ。
  [ -x "$TEXTLINT_DIR/node_modules/.bin/textlint" ] || exit 0

  # Markdown は本文を、それ以外はコメントだけを検査する。
  # textlint が見るのは Markdown の本文だけなので、設定リポジトリのように
  # 日本語の大半がコメント側にあると、入れただけでは大部分が素通りになる。
  local report
  case "$file" in
    *.md | *.mdx | *.markdown)
      report=$("$TEXTLINT_DIR/node_modules/.bin/textlint" \
        --config "$TEXTLINT_DIR/.textlintrc.json" \
        --format compact "$file" 2>/dev/null)
      ;;
    *.yml | *.yaml | *.sh | *.bash | *.nix | *.toml | *.js | *.mjs | *.cjs | *.ts | *.lua)
      report=$(node "$TEXTLINT_DIR/preset-ja-no-ai-tone/scripts/lint-comments.mjs" "$file" 2>/dev/null)
      ;;
    *) exit 0 ;;
  esac
  [ -z "$report" ] && exit 0

  # 出力が長いと後続の判断を圧迫するので、先頭 20 件だけ渡す。
  report=$(head -n 20 <<<"$report")

  if [ "$FILE_MODE" = "block" ]; then
    emit_json "$(jq -nc --arg report "$report" --arg file "$file" '{
      decision: "block",
      reason: ($file + " に AI 文体の指摘がある。指摘箇所を書き直してから次に進むこと。\n" +
               $report + "\n" +
               "機械的に直せるものは `npm --prefix ~/workspace/dotfiles/home/textlint run fix -- " + $file + "` で片付く。" +
               "残りは指摘文が書き直しの方針を示しているので、それに従って本文を直す。")
    }')"
  fi

  emit_json "$(jq -nc --arg report "$report" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("AI 文体の指摘:\n" + $report)
    }
  }')"
}

# --------------------------------------------------------------------
# PreToolUse: 投稿しようとしている文章を送信の直前で検査する
# --------------------------------------------------------------------

# 与えられた本文を lint:text と同じ扱いで検査し、指摘があれば標準出力に返す。
lint_prose() {
  local text=$1 tmp
  # 日本語を含まない本文は対象外。英語の PR まで止める理由がない。
  grep -q '[ぁ-んァ-ヶ一-龠]' <<<"$text" || return 0
  tmp=$(mktemp -t ai-tone.XXXXXX) || return 0
  printf '%s\n' "$text" >"$tmp"
  node "$TEXTLINT_DIR/preset-ja-no-ai-tone/scripts/lint-comments.mjs" --prose "$tmp" 2>/dev/null \
    | sed "s|$tmp|<本文>|"
  rm -f "$tmp"
}

# git commit の実行コマンドからメッセージ本体を取り出す。
# -F <file> / ヒアドキュメント / -m の 3 つの書き方に対応する。
# 取り出せなければ何も返さず、フックは黙って通す。
commit_message_of() {
  local command=$1 file
  file=$(sed -n 's/.*-F[[:space:]]\{1,\}\([^[:space:]]\{1,\}\).*/\1/p' <<<"$command" | head -n 1)
  if [ -n "$file" ] && [ -f "$file" ]; then
    cat "$file"
    return
  fi
  # ヒアドキュメント（<<'MSG' ... MSG）の中身
  awk '
    /<<-?[[:space:]]*.?[A-Za-z_][A-Za-z0-9_]*.?$/ && !inside {
      match($0, /[A-Za-z_][A-Za-z0-9_]*.?$/)
      tag = substr($0, RSTART, RLENGTH)
      gsub(/[^A-Za-z0-9_]/, "", tag)
      inside = 1
      next
    }
    inside && $0 == tag { inside = 0; next }
    inside { print }
  ' <<<"$command"
  # -m "..." / -m '...'
  sed -n "s/.*-m[[:space:]]\{1,\}[\"']\(.*\)[\"'].*/\1/p" <<<"$command"
}

check_post() {
  [ "$POST_MODE" = "off" ] && exit 0
  [ -x "$TEXTLINT_DIR/node_modules/.bin/textlint" ] || exit 0

  local tool text label
  tool=$(jq -r '.tool_name // ""' <<<"$payload")

  case "$tool" in
    # GitHub へ投稿する MCP ツール。PR の本文・タイトル、レビュー、コメントを含む。
    mcp__github__*pull_request* | mcp__github__*issue* | mcp__github__*comment* | mcp__github__*review*)
      text=$(jq -r '[.tool_input.title // "", .tool_input.body // ""] | join("\n\n")' <<<"$payload")
      label="GitHub に投稿しようとしている本文"
      ;;
    Bash)
      local command
      command=$(jq -r '.tool_input.command // ""' <<<"$payload")
      grep -q 'git commit' <<<"$command" || exit 0
      text=$(commit_message_of "$command")
      label="コミットメッセージ"
      ;;
    *) exit 0 ;;
  esac

  [ -z "${text// /}" ] && exit 0

  local report
  report=$(lint_prose "$text")
  [ -z "$report" ] && exit 0
  report=$(head -n 20 <<<"$report")

  if [ "$POST_MODE" = "block" ]; then
    emit_json "$(jq -nc --arg report "$report" --arg label "$label" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ($label + "に AI 文体の指摘がある。書き直してから投稿すること。\n" + $report)
      }
    }')"
  fi

  emit_json "$(jq -nc --arg report "$report" --arg label "$label" '{
    systemMessage: ($label + "の指摘:\n" + $report)
  }')"
}

case "$event" in
  Stop | SubagentStop) check_chat ;;
  PostToolUse) check_file ;;
  PreToolUse) check_post ;;
esac

exit 0
