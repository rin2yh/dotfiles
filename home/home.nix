{
  config,
  lib,
  pkgs,
  ...
}:

let
  # home.username / home.homeDirectory are provided by the nix-darwin module
  # (from users.users.<name>), so the home directory is never hardcoded here.
  dotfilesDir = "${config.home.homeDirectory}/workspace/dotfiles";
  dotfiles = "${dotfilesDir}/home";
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
    dune_3
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
    nixd
    nixfmt-rfc-style
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

  home.activation.claudeCodeNotifier = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    APP="$HOME/Applications/ClaudeCodeNotifier.app"
    ICON="/Applications/Claude.app/Contents/Resources/electron.icns"
    SRC="${dotfiles}/claude/hooks/notify.applescript"

    if [ ! -f "$ICON" ] || [ ! -f "$SRC" ]; then
      exit 0
    fi

    if [ -x "$APP/Contents/MacOS/applet" ] \
       && [ ! "$SRC" -nt "$APP/Contents/MacOS/applet" ] \
       && [ ! "$ICON" -nt "$APP/Contents/Resources/applet.icns" ]; then
      exit 0
    fi

    mkdir -p "$HOME/Applications"
    rm -rf "$APP"
    /usr/bin/osacompile -o "$APP" "$SRC"
    rm -f "$APP/Contents/Resources/Assets.car"
    cp "$ICON" "$APP/Contents/Resources/applet.icns"
    /usr/bin/plutil -replace CFBundleIdentifier -string "dev.yuuki.claude-code-notifier" "$APP/Contents/Info.plist"
    /usr/bin/plutil -replace CFBundleName -string "Claude Code" "$APP/Contents/Info.plist"
    /usr/bin/plutil -remove CFBundleIconName "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/bin/codesign --sign - --force --deep "$APP" >/dev/null 2>&1 || true
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
    /usr/bin/touch "$APP"
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
