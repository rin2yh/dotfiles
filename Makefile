MISE         := $(HOME)/.local/bin/mise
NIX          := /nix/var/nix/profiles/default/bin/nix
DOTFILES_DIR := $(CURDIR)

export PATH := $(HOME)/.local/bin:$(PATH)

.PHONY: setup submodule-init mise-install nix-install darwin-switch tools textlint help

setup: submodule-init mise-install nix-install darwin-switch tools textlint ## Run full setup

submodule-init: ## Initialize and update git submodules
	git submodule update --init --recursive --force

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

darwin-switch: ## Apply nix-darwin + home-manager configuration (flake)
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		sudo darwin-rebuild switch --flake $(DOTFILES_DIR)#default; \
	else \
		sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake $(DOTFILES_DIR)#default; \
	fi
	@echo ""
	@echo "==> Run 'exec zsh -l' to reload the shell with the new configuration."

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

textlint: ## Install the Japanese proofreading toolchain used by the ai-tone hook
	mise exec -- npm --prefix $(DOTFILES_DIR)/home/textlint install
	mise exec -- npm --prefix $(DOTFILES_DIR)/home/textlint test

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
