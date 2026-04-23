BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew

export PATH := $(BREW_PREFIX)/bin:$(PATH)

RSYNC_OPTS := -av --checksum --exclude='.DS_Store' --exclude='.git'

.PHONY: setup brew-install home-deploy brew-bundle config-deploy tools help

setup: brew-install home-deploy brew-bundle config-deploy tools ## Run full setup

brew-install: ## Install Homebrew (if not installed)
	@if [ ! -f "$(BREW)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

home-deploy: ## Deploy home dotfiles (./home/ -> ~/)
	rsync $(RSYNC_OPTS) ./home/ $$HOME/

brew-bundle: ## Install packages via Homebrew (brew bundle --global)
	brew bundle --global

config-deploy: ## Deploy config dotfiles (./config/ -> ~/.config/)
	@mkdir -p "$$HOME/.config"
	rsync $(RSYNC_OPTS) ./config/ $$HOME/.config/

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
