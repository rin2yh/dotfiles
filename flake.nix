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
      # マシンを増やすときは darwinConfigurations に 1 行足す。
      # nix レベルでマシン間に差があるのは username 程度なので、マシンごとの
      # モジュール分割は実際に差分が出てから入れる。
      #
      # networking.hostName は移植性のため全マシン "default" 固定。
      # 適用するマシンはホスト名に依存させず `--flake .#<name>` で明示する。
      mkDarwin =
        {
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
              ;
          };
          modules = [
            ./darwin/configuration.nix
            home-manager.darwinModules.home-manager
            { networking.hostName = "default"; }
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
    in
    {
      darwinConfigurations = {
        default = mkDarwin { };
        work = mkDarwin { username = "yukihayashi"; };
      };
    };
}
