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
  appDescriptions = {
    build = "Build the Home Manager configuration for this repo";
    check = "Run flake checks for this repo";
    darwin-switch = "Apply the nix-darwin and Home Manager configuration";
    fmt = "Format Nix files for this repo";
    help = "List available Nix flake commands";
    switch = "Apply the Home Manager configuration for this repo";
    update = "Update flake inputs, show revisions, and apply the Home Manager configuration";
  };
  helpCommandList = builtins.concatStringsSep "\n" (
    builtins.map (name: "  nix run .#${name}  ${appDescriptions.${name}}") (
      builtins.attrNames appDescriptions
    )
  );
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
    meta.description = appDescriptions.build;
  };

  check = {
    type = "app";
    program = toString (mkScript "check" ../scripts/apps/check.sh { });
    meta.description = appDescriptions.check;
  };

  fmt = {
    type = "app";
    program = toString (
      mkScript "fmt" ../scripts/apps/fmt.sh {
        NIXFMT_BIN = "${pkgs.nixfmt}/bin/nixfmt";
      }
    );
    meta.description = appDescriptions.fmt;
  };

  help = {
    type = "app";
    program = toString (
      mkScript "help" ../scripts/apps/help.sh {
        APP_COMMANDS = helpCommandList;
      }
    );
    meta.description = appDescriptions.help;
  };

  switch = {
    type = "app";
    program = toString (
      mkScript "switch" ../scripts/apps/switch.sh {
        HOME_MANAGER_BIN = homeManagerBin;
        FLAKE_REF = flakeRef;
        NIX_STORE_DIR = builtins.storeDir;
      }
    );
    meta.description = appDescriptions.switch;
  };

  darwin-switch = {
    type = "app";
    program = toString (
      mkScript "darwin-switch" ../scripts/apps/darwin-switch.sh {
        DARWIN_REBUILD_BIN = darwinRebuildBin;
        HOME_CONFIGURATION_NAME = homeConfigurationName;
      }
    );
    meta.description = appDescriptions."darwin-switch";
  };

  update = {
    type = "app";
    program = toString (mkScript "update" ../scripts/apps/update.sh { });
    meta.description = appDescriptions.update;
  };
}
