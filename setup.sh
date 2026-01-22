#!/usr/bin/env bash

# Homebrew の存在チェック
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# mise の存在チェック
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    brew install mise
else
    echo "mise is already installed."
fi

