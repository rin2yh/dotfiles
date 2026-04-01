# My Dotfiles

## Setup

```bash
make
```

This will:
1. Install Homebrew (if not installed)
2. Deploy home dotfiles (`~/`)
3. Install packages via Homebrew (`brew bundle --global`)
4. Deploy config dotfiles (`~/.config/`)
5. Install development tools (mise install, gopls)

### Individual Targets

```bash
make brew-install  # Install Homebrew
make home-link     # home dotfiles only
make brew-bundle   # brew bundle only
make config-link   # config dotfiles only
make tools         # tool installation only
make clean         # remove created symlinks
```

## Structure

```
.
├── config/   # -> ~/.config/
├── home/     # -> ~/
└── Makefile  # Setup tasks
```
