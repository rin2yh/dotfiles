{
  username,
  dotfilesDir,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username dotfilesDir; };
    users.${username} = import ../home/home.nix;
  };
}
