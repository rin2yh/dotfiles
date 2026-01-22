#!/usr/bin/env bash

# dotfilesがあるディレクトリ（このスクリプトの場所）
DOT_HOME_DIR="$HOME/dotfiles/home"

echo "Deploying dotfiles from $DOT_HOME_DIR to $HOME..."

# home配下の全ファイルを対象にループ
find "$DOT_HOME_DIR" -type f -not -name "*.sh" | while read -r src; do
    # ホームディレクトリ内での相対パスを算出
    rel_path="${src#$DOT_HOME_DIR/}"
    target="$HOME/$rel_path"

    # シンボリックリンクを作成（-f で既存ファイルを強制上書き）
    ln -snf "$src" "$target"

    echo "Linked: $rel_path"
done

echo "Done!"
