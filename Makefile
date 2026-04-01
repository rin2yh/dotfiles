DOTFILES_DIR := $(CURDIR)
BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew

export PATH := $(BREW_PREFIX)/bin:$(PATH)

.PHONY: setup brew-install home-link brew-bundle config-link tools clean help

setup: brew-install home-link brew-bundle config-link tools ## Run full setup

brew-install: ## Install Homebrew (if not installed)
	@if [ ! -f "$(BREW)" ]; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

home-link: ## Deploy home dotfiles (./home/ -> ~/)
	@echo "Deploying dotfiles from ./home to $$HOME..."
	@find ./home -maxdepth 1 -mindepth 1 | while read -r src; do \
		rel_path="$${src#./home/}"; \
		target="$$HOME/$$rel_path"; \
		ln -sfn "$(DOTFILES_DIR)/home/$$rel_path" "$$target"; \
		echo "Linked: $$rel_path"; \
	done

brew-bundle: ## Install packages via Homebrew (brew bundle --global)
	brew bundle --global

config-link: ## Deploy config dotfiles (./config/*/ -> ~/.config/)
	@mkdir -p "$$HOME/.config"
	@find ./config -maxdepth 1 -mindepth 1 -type d | while read -r src_dir; do \
		dir_name=$$(basename "$$src_dir"); \
		target="$$HOME/.config/$$dir_name"; \
		ln -sfn "$(DOTFILES_DIR)/config/$$dir_name" "$$target"; \
		echo "Linked: $$dir_name"; \
	done

tools: ## Install development tools (mise install, gopls)
	mise install
	mise exec -- go install golang.org/x/tools/gopls@latest

clean: ## Remove created symlinks
	@echo "Removing symlinks..."
	@find ./home -maxdepth 1 -mindepth 1 | while read -r src; do \
		rel_path="$${src#./home/}"; \
		target="$$HOME/$$rel_path"; \
		if [ -L "$$target" ]; then \
			rm "$$target"; \
			echo "Removed: $$rel_path"; \
		fi; \
	done
	@find ./config -maxdepth 1 -mindepth 1 -type d | while read -r src_dir; do \
		dir_name=$$(basename "$$src_dir"); \
		target="$$HOME/.config/$$dir_name"; \
		if [ -L "$$target" ]; then \
			rm "$$target"; \
			echo "Removed: $$dir_name"; \
		fi; \
	done

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
