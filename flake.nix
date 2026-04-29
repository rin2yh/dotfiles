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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
    }:
    {
      darwinConfigurations."hayashiyuuseis-MacBook-Air" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit self; username = "yuuki"; };
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          { networking.hostName = "hayashiyuuseis-MacBook-Air"; }
        ];
      };
    };
}
