BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew
MISE         := $(HOME)/.local/bin/mise
NIX          := /nix/var/nix/profiles/default/bin/nix
DOTFILES_DIR := $(CURDIR)

export PATH := $(HOME)/.local/bin:$(BREW_PREFIX)/bin:$(PATH)

.PHONY: setup submodule-init brew-install home-deploy brew-bundle config-deploy mise-install nix-install tools clean help

setup: submodule-init brew-install home-deploy brew-bundle config-deploy mise-install nix-install tools ## Run full setup

submodule-init: ## Initialize and update git submodules
	git submodule update --init --recursive --force

brew-install: ## Install Homebrew (if not installed)
	@if [ ! -f "$(BREW)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

home-deploy: ## Deploy home dotfiles (./home/* -> ~/ via symlink)
	@find ./home -maxdepth 1 -mindepth 1 | while read -r src; do \
	    name=$$(basename "$$src"); \
	    target="$$HOME/$$name"; \
	    if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
	        echo "Error: $$target exists as real file/dir."; \
	        exit 1; \
	    fi; \
	    ln -sfn "$(DOTFILES_DIR)/home/$$name" "$$target"; \
	    echo "Linked: $$name"; \
	done

brew-bundle: ## Install packages via Homebrew (brew bundle --global)
	brew bundle --global

config-deploy: ## Deploy config dotfiles (./config/* -> ~/.config/ via symlink)
	@mkdir -p "$$HOME/.config"
	@find ./config -maxdepth 1 -mindepth 1 | while read -r src; do \
	    name=$$(basename "$$src"); \
	    target="$$HOME/.config/$$name"; \
	    if [ -e "$$target" ] && [ ! -L "$$target" ]; then \
	        echo "Error: $$target exists as real file/dir."; \
	        exit 1; \
	    fi; \
	    ln -sfn "$(DOTFILES_DIR)/config/$$name" "$$target"; \
	    echo "Linked: $$name"; \
	done

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

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

clean: ## Remove created symlinks from ~/ and ~/.config/
	@find ./home -maxdepth 1 -mindepth 1 | while read -r src; do \
	    name=$$(basename "$$src"); target="$$HOME/$$name"; \
	    if [ -L "$$target" ]; then rm "$$target" && echo "Removed: $$target"; fi; \
	done
	@find ./config -maxdepth 1 -mindepth 1 | while read -r src; do \
	    name=$$(basename "$$src"); target="$$HOME/.config/$$name"; \
	    if [ -L "$$target" ]; then rm "$$target" && echo "Removed: $$target"; fi; \
	done

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
