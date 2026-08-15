{ username, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = import ../home/home.nix;
  };
}
