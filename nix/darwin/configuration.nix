{
  self,
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  # Nix is managed by the Determinate installer; let it own /etc/nix/nix.conf.
  nix.enable = false;
  security.pam.services.sudo_local.touchIdAuth = true;
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
