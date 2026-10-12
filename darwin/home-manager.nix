{ username, dotfilesDir, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit dotfilesDir; };
    users.${username} = import ../home/home.nix;
  };
}
