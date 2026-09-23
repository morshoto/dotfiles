{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      lib = nixpkgs.lib;
      hostDefinitions = import ./nix/hosts;
      local = if builtins.pathExists ./nix/local.nix then import ./nix/local.nix else { };
      hostName = local.hostName or "apple-silicon";

      _validateHost =
        if builtins.hasAttr hostName hostDefinitions then
          null
        else
          throw "Unknown host '${hostName}'. Choose one of: ${builtins.concatStringsSep ", " (builtins.attrNames hostDefinitions)}";

      localOverrides = builtins.removeAttrs local [ "hostName" ];
      hosts = lib.mapAttrs (
        name: definition: if name == hostName then definition // localOverrides else definition
      ) hostDefinitions;

      mkPkgs =
        host:
        import nixpkgs {
          inherit (host) system;
          config = {
            allowUnfreePredicate = pkg: pkg.pname == "terraform";
          };
        };

      mkHomeModule = host: {
        imports = [ ./nix/home/default.nix ];
        home.username = host.username;
        home.homeDirectory = host.homeDirectory;
        home.stateVersion = "24.11";
      };

      mkHomeSpecialArgs = host: {
        username = host.username;
        homeDirectory = host.homeDirectory;
        dotfilesDir = host.dotfilesDir;
      };

      mkHomeConfiguration =
        _name: host:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs host;
          modules = [ (mkHomeModule host) ];
          extraSpecialArgs = mkHomeSpecialArgs host;
        };

      homeConfigurations = lib.mapAttrs mkHomeConfiguration hosts;
      darwinConfigurations = lib.mapAttrs (
        _name: host:
        nix-darwin.lib.darwinSystem {
          inherit (host) system;
          modules = [
            ./nix/darwin/default.nix
            home-manager.darwinModules.home-manager
            {
              system.primaryUser = host.username;
              users.users.${host.username}.home = host.homeDirectory;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = mkHomeSpecialArgs host;
                users.${host.username} = mkHomeModule host;
              };
            }
          ];
        }
      ) hosts;
      primaryHost = hosts.${hostName};
      primaryPkgs = mkPkgs primaryHost;
      packageSet = import ./nix/packages.nix { pkgs = primaryPkgs; };
      apps = import ./nix/apps.nix {
        pkgs = primaryPkgs;
        homeManager = home-manager;
        nixDarwin = nix-darwin;
        homeConfigurationName = hostName;
      };

      nixFormatCheck = primaryPkgs.runCommand "nix-format-check" {
        nativeBuildInputs = [ primaryPkgs.nixfmt ];
      } ''
        set -euo pipefail

        while IFS= read -r -d "" file; do
          nixfmt --check "$file"
        done < <(find ${./.} -type f -name '*.nix' -print0)

        touch "$out"
      '';

      shellSyntaxCheck = primaryPkgs.runCommand "shell-syntax-check" {
        nativeBuildInputs = with primaryPkgs; [ bash fish zsh ];
      } ''
        set -euo pipefail

        while IFS= read -r -d "" file; do
          bash -n "$file"
        done < <(find ${./scripts} ${./tests} -type f -name '*.sh' -print0)

        while IFS= read -r -d "" file; do
          zsh -n "$file"
        done < <(find ${./zsh} -type f -name '*.zsh' -print0)

        while IFS= read -r -d "" file; do
          fish -n "$file"
        done < <(find ${./fish} -type f -name '*.fish' -print0)

        touch "$out"
      '';

      repositoryTests = primaryPkgs.runCommand "repository-tests" {
        nativeBuildInputs = with primaryPkgs; [ bash git nix ];
      } ''
        set -euo pipefail
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"

        repo_root=${./.}
        for test_script in \
          "$repo_root/tests/test-bootstrap.sh" \
          "$repo_root/tests/test-documentation.sh" \
          "$repo_root/tests/test-host-configurations.sh" \
          "$repo_root/tests/test-darwin-configuration.sh" \
          "$repo_root/tests/test-update-flake-workflow.sh" \
          "$repo_root/tests/test-flake-checks.sh" \
          "$repo_root/tests/test-shared-ai.sh"; do
          bash "$test_script"
        done

        touch "$out"
      '';
    in
    assert _validateHost == null;
    {
      packages.${primaryHost.system} = {
        dotfiles-pkg = packageSet.packageBundle;
        default = packageSet.packageBundle;
      };

      devShells.${primaryHost.system}.default = import ./nix/devshell.nix { pkgs = primaryPkgs; };

      formatter.${primaryHost.system} = primaryPkgs.nixfmt;

      apps.${primaryHost.system} = apps;

      checks.${primaryHost.system} = {
        home-manager-build = homeConfigurations.${hostName}.activationPackage;
        nix-format = nixFormatCheck;
        shell-syntax = shellSyntaxCheck;
        repository-tests = repositoryTests;
      };

      homeConfigurations = homeConfigurations // {
        default = homeConfigurations.${hostName};
      };

      inherit darwinConfigurations;
    };
}
