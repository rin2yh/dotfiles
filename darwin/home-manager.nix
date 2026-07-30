{
  username,
  dotfilesDir,
  profile,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit username dotfilesDir; };
    users.${username}.imports = [
      ../home/home.nix
      ../profiles/${profile}/home.nix
    ];
  };
}
