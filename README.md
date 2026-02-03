# My Dotfiles

## Setup

```bash
./setup.sh
```

This will:
1. Install Homebrew (if not installed)
2. Load PATH from `.zprofile`
3. Run mise tasks in dependency order:
   - `home:link` - Deploy home dotfiles (`~/.Brewfile` etc.)
   - `brew-bundle` - Install packages via Homebrew
   - `config:link` - Deploy config dotfiles (`~/.config/*`)
   - `tools` - Install development tools (mise install, gopls)

### Individual Tasks

```bash
mise run home:link      # home dotfiles only
mise run brew-bundle    # brew bundle only
mise run config:link    # config dotfiles only
mise run tools          # tool installation only
```

## Structure

```
.
├── config/   # -> ~/.config/
├── home/     # -> ~/
├── mise.toml # Task definitions
└── setup.sh  # Bootstrap script
```
