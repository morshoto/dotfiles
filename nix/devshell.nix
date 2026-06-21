{ pkgs }:

let
  pgConfigShim = pkgs.writeShellScriptBin "pg_config" ''
    set -euo pipefail

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
in
pkgs.mkShell {
  packages = with pkgs; [
    cmake
    libpq
    llvm
    pkg-config
    postgresql_16
    postgresql_16.dev
    pgConfigShim
    python311
    swig
  ];

  PG_CONFIG = "${pgConfigShim}/bin/pg_config";
}
