{ pkgs, homeManager }:

let
  homeManagerBin = "${homeManager.packages.${pkgs.system}.home-manager}/bin/home-manager";
in
{
  switch = {
    type = "app";
    program = toString (pkgs.writeShellScript "switch" ''
      set -euo pipefail
      exec ${homeManagerBin} switch --impure --flake .#default "$@"
    '');
    meta.description = "Apply the Home Manager configuration for this repo";
  };

  update = {
    type = "app";
    program = toString (pkgs.writeShellScript "update" ''
      set -euo pipefail
      nix flake update --flake .
      exec nix run --impure .#switch -- "$@"
    '');
    meta.description = "Update flake inputs and apply the Home Manager configuration";
  };
}
