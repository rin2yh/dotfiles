#!/usr/bin/env bash
set -euo pipefail

SRC=${1:?usage: claude-code-notifier.sh <notify.applescript>}
APP="$HOME/Applications/ClaudeCodeNotifier.app"
ICON="/Applications/Claude.app/Contents/Resources/electron.icns"

if [[ ! -f "$ICON" || ! -f "$SRC" ]]; then
  exit 0
fi

if [[ -x "$APP/Contents/MacOS/applet" ]] \
  && [[ ! "$SRC" -nt "$APP/Contents/MacOS/applet" ]] \
  && [[ ! "$ICON" -nt "$APP/Contents/Resources/applet.icns" ]]; then
  exit 0
fi

mkdir -p "$HOME/Applications"
rm -rf "$APP"
/usr/bin/osacompile -o "$APP" "$SRC"
rm -f "$APP/Contents/Resources/Assets.car"
cp "$ICON" "$APP/Contents/Resources/applet.icns"
/usr/bin/plutil -replace CFBundleIdentifier -string "dev.yuuki.claude-code-notifier" "$APP/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "Claude Code" "$APP/Contents/Info.plist"
/usr/bin/plutil -remove CFBundleIconName "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/bin/codesign --sign - --force --deep "$APP" >/dev/null 2>&1 || true
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
/usr/bin/touch "$APP"
