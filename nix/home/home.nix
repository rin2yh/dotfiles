{ config, pkgs, ... }:

let
  repoRoot = "${config.home.homeDirectory}/workspace/dotfiles";
  dotfiles = "${repoRoot}/nix/home";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.username = "yuuki";
  home.homeDirectory = "/Users/yuuki";

  # This value determines the Home Manager release that your configuration is
  # compatible with. See the Home Manager release notes before changing.
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    git
    tree
    zsh-autosuggestions
  ];

  home.file = {
    ".gitconfig".source = mkLink "git/.gitconfig";
    ".zshrc".source = mkLink "zsh/.zshrc";
    ".zprofile".source = mkLink "zsh/.zprofile";
    ".claude".source = mkLink ".claude";
    ".Brewfile".source = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/home/.Brewfile";
  };

  xdg.configFile = {
    "git/ignore".source = mkLink "git/ignore";
    "fastfetch".source = mkLink "fastfetch";
    "starship.toml".source = mkLink "starship/starship.toml";
    "mise".source = mkLink "mise";
    "nvim".source = mkLink "nvim";
    "ghostty".source = mkLink "ghostty";
  };

  programs.home-manager.enable = true;
}
