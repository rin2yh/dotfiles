#!/usr/bin/env bash
# Nix が使えない状態からセットアップするための最小限のブートストラップ。
# Nix 導入後の作業は flake app (`nix run .#<app>`) に委譲する。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX="/nix/var/nix/profiles/default/bin/nix"

echo "==> Initializing git submodules..."
git -C "$DOTFILES_DIR" submodule update --init --recursive --force

if [ ! -e "$NIX" ]; then
  echo "==> Installing Nix..."
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

cat <<EOF

==> Next steps:
    cd "$DOTFILES_DIR"
    nix run .#darwin-switch   # Apply nix-darwin + home-manager configuration
    nix run .#tools           # Install development tools (mise install)
EOF
