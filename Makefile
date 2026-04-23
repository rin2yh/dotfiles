BREW_PREFIX  := /opt/homebrew
BREW         := $(BREW_PREFIX)/bin/brew

export PATH := $(BREW_PREFIX)/bin:$(PATH)

FIND_EXCLUDES := ! -name '.DS_Store' ! -name '.git' ! -path '*/.git/*'
RSYNC_OPTS    := -av --checksum --exclude='.DS_Store' --exclude='.git'

.PHONY: setup submodule-init brew-install home-deploy brew-bundle config-deploy tools clean help

setup: submodule-init brew-install home-deploy brew-bundle config-deploy tools ## Run full setup

submodule-init: ## Initialize and update git submodules
	git submodule update --init --recursive --force

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

clean: ## Remove deployed files from ~/ and ~/.config/ (prompts for confirmation)
	@list() { \
		src_dir="$$1"; dest_dir="$$2"; \
		find "$$src_dir" -type f $(FIND_EXCLUDES) | while read -r src; do \
			rel="$${src#$$src_dir/}"; target="$$dest_dir/$$rel"; \
			[ -f "$$target" ] && echo "$$target"; \
		done; \
	}; \
	files=$$( { list ./home $$HOME; list ./config $$HOME/.config; } ); \
	if [ -z "$$files" ]; then echo "No files to remove."; exit 0; fi; \
	echo "Files to be removed:"; \
	echo "$$files" | sed 's/^/  /'; \
	printf "Continue? [y/N]: "; \
	read ans; \
	case "$$ans" in \
		[yY]|[yY][eE][sS]) echo "$$files" | while read -r f; do rm "$$f" && echo "Removed: $$f"; done ;; \
		*) echo "Aborted." ;; \
	esac

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
