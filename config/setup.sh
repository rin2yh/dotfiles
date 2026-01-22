#!/usr/bin/env bash

# dotfiles/config の絶対パスを取得
DOT_DIR="$HOME/dotfiles/config"

echo "Deploying config directories from $DOT_DIR to $HOME/.config"

# .config ディレクトリ自体が存在しない場合に作成
mkdir -p "$HOME/.config"

find "$DOT_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r src_dir; do
    
    dir_name=$(basename "$src_dir")
    target="$HOME/.config/$dir_name"

    # シンボリックリンクを作成
    # -s: symbolic, -f: force, -n: リンク先がディレクトリでも上書き
    ln -sfn "$src_dir" "$target"
    echo "Linked: $dir_name"
done

echo "Extra setup tasks..."
echo "Installing mise tools..."
mise install

echo "Installing gopls for nvim LSP..."
go install golang.org/x/tools/gopls@latest

echo "Done!"