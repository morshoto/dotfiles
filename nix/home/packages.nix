{ pkgs, ... }:

let
  packageSet = import ../packages.nix { inherit pkgs; };
in
{
  home.packages = packageSet.packageList;
}
