BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew
MISE         := $(HOME)/.local/bin/mise
NIX          := /nix/var/nix/profiles/default/bin/nix
HM           := $(HOME)/.nix-profile/bin/home-manager
HM_USER      ?= yuuki
DOTFILES_DIR := $(CURDIR)

export PATH := $(HOME)/.local/bin:$(BREW_PREFIX)/bin:$(PATH)

.PHONY: setup submodule-init brew-install brew-bundle mise-install nix-install home-manager-switch tools help

setup: submodule-init brew-install mise-install nix-install home-manager-switch brew-bundle tools ## Run full setup

submodule-init: ## Initialize and update git submodules
	git submodule update --init --recursive --force

brew-install: ## Install Homebrew (if not installed)
	@if [ ! -f "$(BREW)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

brew-bundle: ## Install packages via Homebrew (~/.Brewfile is symlinked by home-manager-switch)
	brew bundle --global

mise-install: ## Install mise via curl (if not installed)
	@if [ ! -f "$(MISE)" ]; then \
		echo "Installing mise..."; \
		curl https://mise.run | sh; \
	fi

nix-install: ## Install Nix via official installer (if not installed)
	@if [ ! -e "$(NIX)" ]; then \
		echo "Installing Nix..."; \
		curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install; \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
	fi

home-manager-switch: ## Apply home-manager configuration (flake)
	@if [ -x "$(HM)" ]; then \
		"$(HM)" switch --flake $(DOTFILES_DIR)/nix#$(HM_USER); \
	else \
		nix run home-manager/master -- switch --flake $(DOTFILES_DIR)/nix#$(HM_USER); \
	fi
	@echo ""
	@echo "==> Run 'exec zsh -l' to reload the shell with the new configuration."

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
