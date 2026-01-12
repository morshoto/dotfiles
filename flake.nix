{
  description = "CLI tools managed by Nix (aarch64-darwin)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      maybeTfenv = if pkgs ? tfenv then [ pkgs.tfenv ] else [];

      myPkgs = pkgs.buildEnv {
        name = "my-packages-list";
        pathsToLink = [ "/bin" "/share" "/lib" "/include" ];
        paths = (with pkgs; [
          git
          curl

          google-cloud-sql-proxy  # brew: cloud-sql-proxy
          cmake
          cocoapods
          diff-pdf
          ffmpeg
          gh
          ghq
          go
          golangci-lint
          graphviz
          jdk17
          kubectl                # brew: kubernetes-cli
          lazygit
          lftp
          libpq
          llvm
          maven
          pandoc
          pdftk                  # brew: pdftk-java
          postgresql_16  # または postgresql_15 / postgresql
          poppler-utils
          qpdf
          ripgrep
          swig
          tree
          yq-go                  # brew: yq
        ]) ++ maybeTfenv;
      };
    in
    {
      packages.${system} = {
        my-packages = myPkgs;
        default = myPkgs;
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
