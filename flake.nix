{
  description = "Home Manager configuration";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    let
      requireEnv =
        name:
        let
          value = builtins.getEnv name;
        in
        if value == "" then
          throw "${name} is required; run nix run .#darwin-switch from the dotfiles directory"
        else
          value;
    in
    {
      darwinConfigurations."default" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            self
            nix-homebrew
            homebrew-core
            homebrew-cask
            ;
          username = requireEnv "DOTFILES_USER";
          dotfilesDir = requireEnv "DOTFILES_DIR";
        };
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          { networking.hostName = "default"; }
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };

      apps."aarch64-darwin" =
        let
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        in
        {
          darwin-switch = {
            type = "app";
            program = "${pkgs.writeShellScript "darwin-switch" ''
              set -euo pipefail
              if [ "$(id -u)" -eq 0 ]; then
                echo "Run this app as your macOS user, without sudo." >&2
                exit 1
              fi
              dotfiles_dir="$(pwd -P)"
              sudo /usr/bin/env DOTFILES_USER="$(id -un)" DOTFILES_DIR="$dotfiles_dir" \
                ${nix-darwin.packages.aarch64-darwin.darwin-rebuild}/bin/darwin-rebuild \
                switch --impure --flake "$dotfiles_dir#default"
              echo ""
              echo "==> Run 'exec zsh -l' to reload the shell with the new configuration."
            ''}";
          };

          tools = {
            type = "app";
            program = "${pkgs.writeShellScript "tools" ''
              exec ${pkgs.mise}/bin/mise install
            ''}";
          };

          clean = {
            type = "app";
            program = "${pkgs.writeShellScript "nh-clean" ''
              exec ${pkgs.nh}/bin/nh clean all --keep-since 30d --keep-one
            ''}";
          };
        };
    };
}
