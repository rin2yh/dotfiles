# My Dotfiles

## Setup

```bash
make
```

This will:
1. Initialize git submodules
2. Install Homebrew (if not installed)
3. Install Nix (if not installed)
4. Apply Home Manager configuration (symlinks `./nix/home/*` into `~/` and `~/.config/`)
5. Install packages via Homebrew (`brew bundle --global`)
6. Install development tools (mise install, gopls)

Home Manager uses `mkOutOfStoreSymlink`, so edits in the repo are reflected
immediately in `$HOME` without re-running `make`.

### Individual Targets

```bash
make submodule-init # initialize git submodules
make brew-install   # Install Homebrew
make nix-install    # Install Nix
make hm-switch      # Apply Home Manager configuration
make brew-bundle    # brew bundle only
make tools          # tool installation only
```

## Structure

```
.
├── home/.Brewfile  # -> ~/.Brewfile (managed via HM)
├── nix/
│   ├── flake.nix   # Home Manager flake
│   └── home/       # Source for ~/ and ~/.config/ entries
└── Makefile        # Setup tasks
```
