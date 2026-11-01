#!/usr/bin/env bash
set -euo pipefail

APP=${1:?usage: claude-code-notifier.sh <app> <icon> <source>}
ICON=${2:?usage: claude-code-notifier.sh <app> <icon> <source>}
SRC=${3:?usage: claude-code-notifier.sh <app> <icon> <source>}

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
