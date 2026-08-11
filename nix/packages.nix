{ pkgs }:

let
  hasTfenv = pkgs ? tfenv;
  terraformPackages = if hasTfenv then [ pkgs.tfenv ] else [ pkgs.terraform ];
  pandocLua = pkgs.pandoc.overrideAttrs (oldAttrs: {
    pname = "pandoc-with-lua";
    configureFlags = (oldAttrs.configureFlags or [ ]) ++ [
      "-f"
      "lua"
    ];
  });
  agentBrowser = pkgs.stdenv.mkDerivation {
    pname = "agent-browser";
    version = "0.33.2";

    src = pkgs.fetchurl {
      url = "https://github.com/vercel-labs/agent-browser/releases/download/v0.33.2/agent-browser-darwin-arm64";
      hash = "sha256-y7UXkCvKo7emOE/Z8l3SdNo98rtqO6nD6FgG14ITwms=";
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 "$src" "$out/bin/agent-browser"
    '';
  };

  packageList =
    (with pkgs; [
      git
      delta
      git-lfs
      codex
      curl
      nodejs_22
      pnpm
      agentBrowser
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
      kaggle
      llvmPackages.openmp
      maven
      pandocLua
      pdftk
      postgresql_16
      poppler-utils
      python311
      pyenv
      qpdf
      stripe-cli
      ripgrep
      tree
      yq-go
    ])
    ++ terraformPackages;
in
{
  inherit packageList;

  packageBundle = pkgs.buildEnv {
    name = "dotfiles-pkg";
    pathsToLink = [
      "/bin"
      "/share"
    ];
    paths = packageList;
  };
}
