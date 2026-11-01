{
  config,
  lib,
  pkgs,
  dotfilesDir,
  ...
}:

let
  dotfiles = "${dotfilesDir}/home";
  go = pkgs.go;
  # Nixpkgs' default Go builder can lag behind point security releases.
  buildGoModule = pkgs.buildGoModule.override { inherit go; };
  lazydocker = pkgs.lazydocker.override { inherit buildGoModule; };
  lazygit = pkgs.lazygit.override { inherit buildGoModule; };
  terraform-ls = pkgs.terraform-ls.override { inherit buildGoModule; };
in
{
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
    gopls
    google-cloud-sdk
    jq
    lazydocker
    lazygit
    lua-language-server
    mise
    neovim
    nixd
    nixfmt
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
    ollama
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # This config applies to the curl CLI only; Git, gh, and other TLS clients use their own settings.
    ".curlrc".text = ''
      cacert = "/etc/ssl/certs/ca-certificates.crt"
    '';

    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/git/.gitconfig";

    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zsh/.zshrc";
    ".zprofile".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zsh/.zprofile";

    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/settings.json";
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/CLAUDE.md";
    ".claude/statusline.js".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/statusline.js";
    ".claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/rules";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/skills";
    ".claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/claude/hooks";
  };

  xdg.configFile = {
    "git/ignore".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/git/ignore";
    "mise/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/mise/config.toml";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
    "starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/starship/starship.toml";
    "textlint".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/textlint";
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/fastfetch";
    "ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/ghostty";
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
  #  /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  home.activation.claudeCodeNotifier = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.bash}/bin/bash "${dotfiles}/scripts/claude-code-notifier.sh" "${dotfiles}/claude/hooks/notify.applescript"
  '';

  programs.nh = {
    enable = true;
    flake = dotfilesDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 30d --keep-one";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
