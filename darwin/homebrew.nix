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
    mutableTaps = false;
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
      cleanup = "zap";
    };
    global.autoUpdate = false;
    casks = [
      "claude"
      "discord"
      "fuwari"
      "ghostty"
      "homerow"
      "notion"
      "orbstack"
      "raycast"
      "slack"
    ];
  };
}
