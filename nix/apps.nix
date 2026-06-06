{
  pkgs,
  homeManager,
  homeConfigurationName,
}:

let
  homeManagerBin =
    "${homeManager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager}/bin/home-manager";
  flakeRef = "path:$PWD#${homeConfigurationName}";
in
{
  build = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "build" ''
        set -euo pipefail
        exec ${homeManagerBin} build --impure --flake "${flakeRef}" "$@"
      ''
    );
    meta.description = "Build the Home Manager configuration for this repo";
  };

  check = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "check" ''
        set -euo pipefail
        exec nix flake check "$@" "path:$PWD"
      ''
    );
    meta.description = "Run flake checks for this repo";
  };

  fmt = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "fmt" ''
        set -euo pipefail
        files=()
        while IFS= read -r -d "" file; do
          files+=("$file")
        done < <(find . -type f -name "*.nix" -print0)

        if [ "''${#files[@]}" -eq 0 ]; then
          exit 0
        fi

        exec ${pkgs.nixfmt}/bin/nixfmt "$@" "''${files[@]}"
      ''
    );
    meta.description = "Format Nix files for this repo";
  };

  switch = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "switch" ''
        set -euo pipefail
        exec ${homeManagerBin} switch -b hm-backup --impure --flake "${flakeRef}" "$@"
      ''
    );
    meta.description = "Apply the Home Manager configuration for this repo";
  };

  update = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "update" ''
        set -euo pipefail
        nix flake update --flake "path:$PWD"
        exec nix run "path:$PWD#switch" -- "$@"
      ''
    );
    meta.description = "Update flake inputs and apply the Home Manager configuration";
  };
}
