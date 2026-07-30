MISE         := $(HOME)/.local/bin/mise
NIX          := /nix/var/nix/profiles/default/bin/nix
DOTFILES_DIR := $(CURDIR)

# 適用するプロファイル (profiles/<name>/)。
# 初回は `make darwin-switch PROFILE=work` のように指定すると .current-profile に
# 記録され、以降は引数なしで同じプロファイルが使われる。
PROFILE_FILE  := $(CURDIR)/.current-profile
SAVED_PROFILE := $(shell cat $(PROFILE_FILE) 2>/dev/null || echo default)
PROFILE       ?= $(SAVED_PROFILE)

export PATH := $(HOME)/.local/bin:$(PATH)

.PHONY: setup submodule-init mise-install nix-install darwin-switch tools profile help

setup: submodule-init mise-install nix-install darwin-switch tools ## Run full setup

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

darwin-switch: ## Apply nix-darwin + home-manager configuration (flake, PROFILE=<name>)
	@echo "==> Applying profile '$(PROFILE)'"
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		sudo darwin-rebuild switch --flake $(DOTFILES_DIR)#$(PROFILE); \
	else \
		sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake $(DOTFILES_DIR)#$(PROFILE); \
	fi
	@echo "$(PROFILE)" > $(PROFILE_FILE)
	@echo ""
	@echo "==> Run 'exec zsh -l' to reload the shell with the new configuration."

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

profile: ## Show the profile that darwin-switch will apply
	@echo "$(PROFILE)"

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
