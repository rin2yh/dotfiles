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
make brew-install   # Install Homebrew
make home-deploy    # home dotfiles only
make brew-bundle    # brew bundle only
make config-deploy  # config dotfiles only
make tools          # tool installation only
make clean-check    # preview files that clean would remove
make clean          # remove deployed files
```

## Structure

```
.
├── config/   # -> ~/.config/
├── home/     # -> ~/
└── Makefile  # Setup tasks
```
