{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/workspace/dotfiles/nix/home";
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "yuuki";
  home.homeDirectory = "/Users/yuuki";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    emmet-language-server
    fastfetch
    fzf
    git
    go
    google-cloud-sdk
    lazydocker
    lazygit
    lua-language-server
    neovim
    ripgrep
    shfmt
    starship
    terraform-ls
    tree
    tree-sitter
    typescript
    typescript-language-server
    vscode-langservers-extracted
    zenn-cli
    zoxide
    zsh-autosuggestions
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/git/.gitconfig";

    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/settings.json";
    ".claude/CLAUDE.md".source     = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/CLAUDE.md";
    ".claude/statusline.js".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/statusline.js";
    ".claude/rules".source         = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/rules";
    ".claude/skills".source        = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/skills";
  };

  xdg.configFile = {
    "git/ignore".source       = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/git/ignore";
    "mise/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/mise/config.toml";
    "nvim".source             = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    "starship.toml".source    = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship/starship.toml";
    "fastfetch".source        = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fastfetch";
    "ghostty".source          = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/yuuki/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
