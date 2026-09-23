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

      homeConfigurations = homeConfigurations // {
        default = homeConfigurations.${hostName};
      };

      inherit darwinConfigurations;
    };
}
