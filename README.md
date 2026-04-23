# My Dotfiles

## Setup

```bash
make
```

This will:
1. Initialize git submodules
2. Install Homebrew (if not installed)
3. Deploy home dotfiles (`~/`)
4. Install packages via Homebrew (`brew bundle --global`)
5. Deploy config dotfiles (`~/.config/`)
6. Install development tools (mise install, gopls)

### Individual Targets

```bash
make submodule-init # initialize git submodules
make brew-install   # Install Homebrew
make home-deploy    # home dotfiles only
make brew-bundle    # brew bundle only
make config-deploy  # config dotfiles only
make tools          # tool installation only
make clean          # remove deployed files (prompts for confirmation)
```

## Structure

```
.
├── config/   # -> ~/.config/
├── home/     # -> ~/
└── Makefile  # Setup tasks
```
