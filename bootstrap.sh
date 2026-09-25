#!/usr/bin/env bash
# Nix が使えない状態からセットアップするための最小限のブートストラップ。
# Nix 導入後の作業は flake app (`nix run .#<app>`) に委譲する。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX="/nix/var/nix/profiles/default/bin/nix"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Command Line Tools are required for Git and Homebrew." >&2
  echo "Run 'xcode-select --install', finish the installation, then rerun ./bootstrap.sh." >&2
  exit 1
fi

echo "==> Initializing git submodules..."
git -C "$DOTFILES_DIR" submodule update --init --recursive --force

if [ ! -e "$NIX" ]; then
  echo "==> Installing Nix..."
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
fi

cat <<EOF

==> Next steps:
    cd "$DOTFILES_DIR"
    exec zsh -l              # Reload PATH after installing Nix
    nix run .#darwin-switch   # Apply nix-darwin + home-manager configuration
    exec zsh -l              # Reload PATH before installing tools
    nix run .#tools           # Install development tools (mise install)
EOF
