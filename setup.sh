#!/usr/bin/env bash
set -euo pipefail

# Homebrew の存在チェック
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Homebrew経由で他ツールのインストール
echo "Installing packages via Homebrew..."
TOOLS=("mise" "ghq" "peco" "zsh-autosuggestions" "tree")
for tool in "${TOOLS[@]}"; do
    if ! brew list "$tool" &> /dev/null; then
        echo "Installing $tool..."
        brew install "$tool"
    else
        echo "$tool is already installed."
    fi
done


# Homebrew Cask経由でアプリケーションのインストール
echo "Installing applications via Homebrew Cask..."
APPS=("ghostty" "raycast" "orbstack" "fuwari" "slack" "discord" "notion" "claude")
for app in "${APPS[@]}"; do
    if ! brew list --cask "$app" &> /dev/null; then
        echo "Installing $app..."
        brew install --cask "$app"
    else
        echo "$app is already installed."
    fi
done

echo "Setup completed."