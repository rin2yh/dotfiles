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
    {
      darwinConfigurations."default" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            self
            nix-homebrew
            homebrew-core
            homebrew-cask
            ;
          username = "yuuki";
        };
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          { networking.hostName = "default"; }
          nix-homebrew.darwinModules.nix-homebrew
        ];
      };
    };
}
