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
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHome = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/home.nix ];
        extraSpecialArgs = { inherit username; };
      };
      mkDarwin = hostname: nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin/configuration.nix
          { networking.hostName = hostname; }
        ];
      };
    in
    {
      homeConfigurations = {
        "yuuki" = mkHome "yuuki";
      };
      darwinConfigurations = {
        "hayashiyuuseis-MacBook-Air" = mkDarwin "hayashiyuuseis-MacBook-Air";
      };
    };
}
