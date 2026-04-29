BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew
MISE         := $(HOME)/.local/bin/mise
NIX          := /nix/var/nix/profiles/default/bin/nix
HM           := $(HOME)/.nix-profile/bin/home-manager
DOTFILES_DIR := $(CURDIR)
HM_FLAKE     := $(DOTFILES_DIR)/nix#yuuki

export PATH := $(HOME)/.local/bin:$(BREW_PREFIX)/bin:$(PATH)

.PHONY: setup submodule-init brew-install brew-bundle nix-install hm-switch mise-install tools help

setup: submodule-init brew-install nix-install hm-switch brew-bundle mise-install tools ## Run full setup

submodule-init: ## Initialize and update git submodules
	git submodule update --init --recursive --force

brew-install: ## Install Homebrew (if not installed)
	@if [ ! -f "$(BREW)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

brew-bundle: ## Install packages via Homebrew (brew bundle --global)
	brew bundle --global

nix-install: ## Install Nix via official installer (if not installed)
	@if [ ! -e "$(NIX)" ]; then \
		echo "Installing Nix..."; \
		curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install; \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
	fi

hm-switch: ## Apply Home Manager configuration (creates ~/ and ~/.config symlinks)
	@if [ -x "$(HM)" ]; then \
		"$(HM)" switch --flake "$(HM_FLAKE)" -b backup; \
	else \
		"$(NIX)" run --extra-experimental-features 'nix-command flakes' \
			home-manager/master -- switch --flake "$(HM_FLAKE)" -b backup; \
	fi

mise-install: ## Install mise via curl (if not installed)
	@if [ ! -f "$(MISE)" ]; then \
		echo "Installing mise..."; \
		curl https://mise.run | sh; \
	fi

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
