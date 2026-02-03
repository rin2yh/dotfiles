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
fi

# PATH 設定 (zprofile を読み込む)
source ./home/.zprofile

# Step 2: mise タスク実行
echo ""
echo "[2/2] Running mise setup tasks..."

# mise trust してから実行
mise trust
mise run setup

echo ""
echo "=== Setup completed! ==="
