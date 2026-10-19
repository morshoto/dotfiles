codexNixpkgs: final: _prev: {
  codex = codexNixpkgs.legacyPackages.${final.stdenv.hostPlatform.system}.codex;
}
