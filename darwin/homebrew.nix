{
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
  username,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      upgrade = true;
      autoUpdate = false;
      cleanup = "none";
    };
    global.autoUpdate = false;
    casks = [
      "claude"
      "discord"
      "font-jetbrains-mono-nerd-font"
      "fuwari"
      "ghostty"
      "homerow"
      "notion"
      "orbstack"
      "raycast"
      "slack"
      "wezterm"
    ];
  };
}
