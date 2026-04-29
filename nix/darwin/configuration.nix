{
  self,
  username,
  ...
}:
{
  system = {
    stateVersion = 6;
    configurationRevision = self.rev or self.dirtyRev or null;

    primaryUser = username;
  };

  users.users.${username}.home = "/Users/${username}";

  nixpkgs.hostPlatform = "aarch64-darwin";
  # Nix is managed by the Determinate installer; let it own /etc/nix/nix.conf.
  nix.enable = false;

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
