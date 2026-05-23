{
  description = "morshoto dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      hostName = "apple-silicon";
      hostDefaults = import ./nix/hosts/apple-silicon.nix;
      local =
        if builtins.pathExists ./nix/local.nix then
          import ./nix/local.nix
        else
          builtins.throw "Create nix/local.nix from nix/local.example.nix before evaluating this flake.";
      host = hostDefaults // local;

      pkgs = import nixpkgs {
        inherit (host) system;
        config = {
          allowUnfreePredicate = pkg: pkg.pname == "terraform";
        };
      };

      packageSet = import ./nix/packages.nix { inherit pkgs; };
      apps = import ./nix/apps.nix {
        inherit pkgs;
        homeManager = home-manager;
        homeConfigurationName = hostName;
      };

      homeConfiguration = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./nix/home/default.nix
          {
            home.username = host.username;
            home.homeDirectory = host.homeDirectory;
            home.stateVersion = "24.11";
          }
        ];

        extraSpecialArgs = {
          inherit (host) username homeDirectory dotfilesDir;
        };
      };
    in
    {
      packages.${host.system} = {
        morshoto-pkg = packageSet.packageBundle;
        default = packageSet.packageBundle;
      };

      devShells.${host.system}.default = import ./nix/devshell.nix { inherit pkgs; };

      formatter.${host.system} = pkgs.nixfmt;

      apps.${host.system} = apps;

      homeConfigurations = {
        "${hostName}" = homeConfiguration;
        default = homeConfiguration;
      };
    };
}
