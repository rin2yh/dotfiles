#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

echo "=== dotfiles setup ==="

# Step 1: Homebrew インストール
echo ""
echo "[1/2] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon Mac の PATH 設定
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

# Step 2: mise インストール & タスク実行
echo ""
echo "[2/2] Installing mise and running setup tasks..."
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    brew install mise
fi

# mise trust してから実行
mise trust
mise run setup

echo ""
echo "=== Setup completed! ==="
