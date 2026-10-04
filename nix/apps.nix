{
  pkgs,
  homeManager,
  nixDarwin,
  homeConfigurationName,
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  homeManagerBin = "${homeManager.packages.${system}.home-manager}/bin/home-manager";
  darwinRebuildBin = "${nixDarwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild";
  flakeRef = "path:$PWD#${homeConfigurationName}";
  mkScript =
    name: file: substitutions:
    pkgs.writeShellScript name (
      builtins.replaceStrings (builtins.map (key: "@${key}@") (
        builtins.attrNames substitutions
      )) (builtins.attrValues substitutions) (builtins.readFile file)
    );
in
{
  build = {
    type = "app";
    program = toString (
      mkScript "build" ../scripts/apps/build.sh {
        HOME_MANAGER_BIN = homeManagerBin;
        FLAKE_REF = flakeRef;
      }
    );
    meta.description = "Build the Home Manager configuration for this repo";
  };

  check = {
    type = "app";
    program = toString (mkScript "check" ../scripts/apps/check.sh { });
    meta.description = "Run flake checks for this repo";
  };

  fmt = {
    type = "app";
    program = toString (
      mkScript "fmt" ../scripts/apps/fmt.sh {
        NIXFMT_BIN = "${pkgs.nixfmt}/bin/nixfmt";
      }
    );
    meta.description = "Format Nix files for this repo";
  };

  switch = {
    type = "app";
    program = toString (
      mkScript "switch" ../scripts/apps/switch.sh {
        HOME_MANAGER_BIN = homeManagerBin;
        FLAKE_REF = flakeRef;
      }
    );
    meta.description = "Apply the Home Manager configuration for this repo";
  };

  darwin-switch = {
    type = "app";
    program = toString (
      mkScript "darwin-switch" ../scripts/apps/darwin-switch.sh {
        DARWIN_REBUILD_BIN = darwinRebuildBin;
        HOME_CONFIGURATION_NAME = homeConfigurationName;
      }
    );
    meta.description = "Apply the nix-darwin and Home Manager configuration";
  };

  update = {
    type = "app";
    program = toString (mkScript "update" ../scripts/apps/update.sh { });
    meta.description = "Update flake inputs and apply the Home Manager configuration";
  };
}
