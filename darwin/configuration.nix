{
  self,
  username,
  ...
}:
{
  imports = [
    ./home-manager.nix
    ./homebrew.nix
  ];

  system = {
    stateVersion = 6;
    configurationRevision = self.rev or self.dirtyRev or null;

    primaryUser = username;

    defaults = {
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = true;
        "com.apple.swipescrolldirection" = false;
        "com.apple.trackpad.scaling" = 3.0;
        "com.apple.springing.enabled" = true;
        "com.apple.springing.delay" = 0.5;
        "com.apple.trackpad.forceClick" = true;
        "com.apple.keyboard.fnState" = true;
        AppleInterfaceStyleSwitchesAutomatically = true;
        AppleSpacesSwitchOnActivate = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };

      dock = {
        autohide = true;
        tilesize = 64;
        mru-spaces = true;
        expose-group-apps = false;
        show-recents = false;
        mineffect = "genie";
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
      };

      trackpad = {
        Clicking = true;
        FirstClickThreshold = 1;
      };

      finder = {
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXSortFoldersFirst = true;
        QuitMenuItem = true;
      };

      screencapture = {
        location = "~/Desktop";
        type = "png";
        disable-shadow = true;
      };

      loginwindow = {
        GuestEnabled = false;
        SHOWFULLNAME = false;
      };

      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      LaunchServices = {
        LSQuarantine = false;
      };

      menuExtraClock = {
        ShowAMPM = true;
        ShowDayOfWeek = true;
        ShowDate = 0;
      };

      WindowManager = {
        AutoHide = true;
        HideDesktop = true;
        StageManagerHideWidgets = true;
        AppWindowGroupingBehavior = true;
      };

      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleLanguages = [
            "en-JP"
            "ja-JP"
          ];
          AppleLocale = "en_JP";
          AppleMiniaturizeOnDoubleClick = false;
          "com.apple.sound.beep.flash" = false;
          "com.apple.sound.uiaudio.enabled" = false;
        };
        "com.apple.windowserver" = {
          DisplayResolutionEnabled = true;
        };
      };
    };
  };

  users.users.${username}.home = "/Users/${username}";

  nixpkgs.hostPlatform = "aarch64-darwin";
  # Nix is managed by the Determinate installer; let it own /etc/nix/nix.conf.
  nix.enable = false;

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
