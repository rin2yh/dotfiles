#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)
(
  sleep 0.5
  IFS=$'\x1f' read -r event message cwd transcript <<< "$(jq -r '[.hook_event_name // "", .message // "", .cwd // "", .transcript_path // ""] | join("")' <<< "$payload")"

  if [[ $cwd == */*/* ]]; then
    parent=${cwd%/*}
    title="${parent##*/}/${cwd##*/}"
  else
    title=${cwd##*/}
  fi
  : "${title:=Claude Code}"

  case "$event" in
    Stop)
      body=""
      if [ -f "$transcript" ]; then
        body=$(tail -n 500 "$transcript" | tail -r | jq -r '
          select(.type=="assistant" and .message.role=="assistant")
          | .message.content
          | if type=="string" then . else (map(select(.type=="text") | .text) | join(" ")) end
          | gsub("^\\s+|\\s+$"; "")
          | select(length > 0)
        ' 2>/dev/null | head -n 1 | tr '\n\r\t' '   ' | head -c 200)
      fi
      body=${body:-応答完了}
      ;;
    Notification) body=${message:-入力待ち} ;;
    "") exit 0 ;;
    *) body=${message:-$event} ;;
  esac

  APP=$HOME/Applications/ClaudeCodeNotifier.app
  if [ -x "$APP/Contents/MacOS/applet" ]; then
    CC_INVOCATION=1 CC_BODY=$body CC_TITLE=$title "$APP/Contents/MacOS/applet" >/dev/null 2>&1
  fi
) &
disown
