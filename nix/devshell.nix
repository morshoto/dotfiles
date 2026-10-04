{ pkgs }:

let
  pgConfigShim = pkgs.writeShellScriptBin "pg_config" (
    builtins.replaceStrings
      [
        "@INCLUDEDIR@"
        "@INCLUDEDIR_SERVER@"
        "@LIBDIR@"
        "@BINDIR@"
        "@VERSION@"
      ]
      [
        "${pkgs.postgresql_16.dev}/include"
        "${pkgs.postgresql_16.dev}/include/server"
        "${pkgs.postgresql_16.lib}/lib"
        "${pkgs.postgresql_16}/bin"
        "PostgreSQL ${pkgs.postgresql_16.version}"
      ]
      (builtins.readFile ../scripts/pg-config.sh)
  );
in
pkgs.mkShell {
  packages = with pkgs; [
    cmake
    gitleaks
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
