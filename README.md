# My Dotfiles

## Setup

```bash
make
```

This will:
1. Initialize git submodules
2. Install Homebrew (if not installed)
3. Deploy home dotfiles (symlink `./home/*` -> `~/`)
4. Install packages via Homebrew (`brew bundle --global`)
5. Install mise (if not installed)
6. Install Nix (if not installed)
7. Apply home-manager configuration (`home-manager switch --flake ./nix#yuuki`)
8. Install development tools (mise install, gopls)

Entries are deployed as directory-level symlinks, so edits on either side (repo or `$HOME`) are reflected immediately without re-running `make`.

### Individual Targets

```bash
make submodule-init       # initialize git submodules
make brew-install         # Install Homebrew
make home-deploy          # home dotfiles only (symlink)
make brew-bundle          # brew bundle only
make mise-install         # Install mise
make nix-install          # Install Nix
make home-manager-switch  # Apply home-manager configuration
make tools                # tool installation only
make clean                # remove created symlinks
```

## Structure

```
.
├── config/   # -> ~/.config/
├── home/     # -> ~/
└── Makefile  # Setup tasks
```
