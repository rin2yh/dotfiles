#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

echo "=== dotfiles setup ==="

# Step 1: Homebrew インストール
echo ""
echo "[1/3] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# .zprofile をリンクして source (Homebrew 環境設定のため)
ln -snf "$DOTFILES_DIR/home/.zprofile" "$HOME/.zprofile"
source "$HOME/.zprofile"

# Step 2: mise インストール (未インストールの場合)
if ! command -v mise &> /dev/null; then
    echo ""
    echo "[2/3] Installing mise via Brewfile..."

    # home:link (Brewfile のシンボリックリンク作成)
    ln -snf "$(pwd)/home/.Brewfile" "$HOME/.Brewfile"
    echo "Linked: .Brewfile"

    # brew bundle で mise をインストール
    brew bundle --global

    # 初回のみ trust
    mise trust
fi

# Step 3: mise タスク実行
echo ""
echo "[3/3] Running mise setup tasks..."
mise run setup

echo ""
echo "=== Setup completed! ==="
