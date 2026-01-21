#!/usr/bin/env bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/mise"

# すでに実体のディレクトリがある場合はバックアップ（初回のみ）
if [ -d "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
  mv "$TARGET_DIR" "${TARGET_DIR}_backup"
fi

# 親ディレクトリを作成（~/.config がない場合のため）
mkdir -p "$(dirname "$TARGET_DIR")"

# ディレクトリごとシンボリックリンクを作成
ln -sfn "$SCRIPT_DIR" "$TARGET_DIR"

echo "Linked $SCRIPT_DIR to $TARGET_DIR"
