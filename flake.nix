{
  description = "CLI tools managed by Nix (aarch64-darwin)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: pkg.pname == "terraform";
        };
      };

      maybeTfenv = if pkgs ? tfenv then [ pkgs.tfenv ] else [];

      pgConfigShim = pkgs.writeShellScriptBin "pg_config" ''
        set -euo pipefail

        # 16.11 に揃える
        INCLUDEDIR="${pkgs.postgresql_16.dev}/include"
        INCLUDEDIR_SERVER="${pkgs.postgresql_16.dev}/include/server"
        LIBDIR="${pkgs.postgresql_16.lib}/lib"
        BINDIR="${pkgs.postgresql_16}/bin"
        VERSION="PostgreSQL ${pkgs.postgresql_16.version}"


        case "''${1:-}" in
          --version) echo "$VERSION" ;;
          --includedir) echo "$INCLUDEDIR" ;;
          --includedir-server) echo "$INCLUDEDIR_SERVER" ;;
          --libdir) echo "$LIBDIR" ;;
          --bindir) echo "$BINDIR" ;;
          --cppflags|--cflags) echo "-I$INCLUDEDIR -I$INCLUDEDIR_SERVER" ;;
          --ldflags) echo "-L$LIBDIR" ;;
          --libs) echo "-L$LIBDIR -lpq" ;;
          *)
            echo "pg_config shim (fixed Nix paths). Supported:" >&2
            echo "  --version --includedir --includedir-server --libdir --bindir --cppflags --cflags --ldflags --libs" >&2
            exit 2
            ;;
        esac
      '';


      myPkgs = pkgs.buildEnv {
        name = "morshoto-pkg";
        pathsToLink = [ "/bin" "/share" ];
        paths = (with pkgs; [
          git
          curl

          google-cloud-sql-proxy
          cocoapods
          diff-pdf
          ffmpeg
          fvm
          gh
          ghq
          go
          golangci-lint
          graphviz
          jdk17
          kubectl
          lazygit
          lftp
          llvmPackages.openmp
          maven
          pandoc
          pdftk
          postgresql_16
          poppler-utils
          pyenv
          qpdf
          stripe-cli
          ripgrep
          terraform
          tree
          yq-go
        ]) ++ maybeTfenv;
      };
    in
    {
      packages.${system} = {
        morshoto-pkg = myPkgs;
        default = myPkgs;
      };


      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          libpq
          llvm
          pkg-config
          postgresql_16
          postgresql_16.dev
          pgConfigShim
          swig
        ];
        PG_CONFIG = "${pgConfigShim}/bin/pg_config";
      };

      apps.${system}.update = {
        type = "app";
        program = toString (pkgs.writeShellScript "update" ''
          set -euo pipefail
          nix flake update
          nix profile remove my-packages || true
          nix profile add --profile ~/.nix-profile --priority 50 .#my-packages

        '');
        meta = {
          description = "Update flake.lock and refresh installed nix profile packages";
        };
      };
    };
}
