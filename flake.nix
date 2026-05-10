{
  description = "morshoto dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      username = "shotomorisaki";
      homeDirectory = "/Users/${username}";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: pkg.pname == "terraform";
        };
      };

      packageSet = import ./nix/packages.nix { inherit pkgs; };
      apps = import ./nix/apps.nix {
        inherit pkgs username;
        homeManager = home-manager;
      };
    in
    {
      packages.${system} = {
        morshoto-pkg = packageSet.packageBundle;
        default = packageSet.packageBundle;
      };

      devShells.${system}.default = import ./nix/devshell.nix { inherit pkgs; };

      apps.${system} = apps;

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./nix/home/default.nix
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.stateVersion = "24.11";
          }
        ];

        extraSpecialArgs = {
          inherit username homeDirectory;
        };
      };
    };
}
