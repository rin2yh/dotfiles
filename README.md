# My Dotfiles

## Setup

```bash
make
```

This will:
1. Initialize git submodules
2. Install Homebrew (if not installed)
3. Install mise (if not installed)
4. Install Nix (if not installed)
5. Apply nix-darwin + home-manager configuration (`darwin-rebuild switch --flake .#<hostname>`)
6. Install packages via Homebrew (`brew bundle --global`)
7. Install development tools (`mise install`, `gopls`)

### Individual Targets

```bash
make submodule-init   # Initialize and update git submodules
make brew-install     # Install Homebrew (if not installed)
make brew-bundle      # Install packages via Homebrew
make mise-install     # Install mise via curl (if not installed)
make nix-install      # Install Nix via official installer (if not installed)
make darwin-switch    # Apply nix-darwin + home-manager configuration (flake)
make tools            # Install development tools (mise install, gopls)
make help             # Show available targets
```

## Structure

```
.
├── flake.nix
├── darwin/         # nix-darwin システム設定 + home-manager 統合
├── home/           # home-manager 配下の各ツール設定
└── Makefile
```
