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
      # プロファイル 1 つ = マシン 1 台分の設定。
      # 全マシン共通の設定は darwin/ と home/ に置き、マシン固有の差分だけを
      # profiles/<name>/{darwin,home}.nix に書く。
      #
      # networking.hostName は移植性のため全プロファイル "default" 固定。
      # プロファイルの選択はホスト名に依存させず `--flake .#<profile>` で明示する。
      mkDarwin =
        {
          profile,
          username ? "yuuki",
          dotfilesDir ? "/Users/${username}/workspace/dotfiles",
        }:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              self
              nix-homebrew
              homebrew-core
              homebrew-cask
              username
              dotfilesDir
              profile
              ;
          };
          modules = [
            ./darwin/configuration.nix
            home-manager.darwinModules.home-manager
            { networking.hostName = "default"; }
            nix-homebrew.darwinModules.nix-homebrew
            ./profiles/${profile}/darwin.nix
          ];
        };
    in
    {
      darwinConfigurations = {
        default = mkDarwin { profile = "default"; };
        work = mkDarwin { profile = "work"; };
      };
    };
}
