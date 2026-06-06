{ pkgs }:

let
  hasTfenv = pkgs ? tfenv;
  terraformPackages = if hasTfenv then [ pkgs.tfenv ] else [ pkgs.terraform ];

  packageList =
    (with pkgs; [
      git
      delta
      git-lfs
      curl
      nodejs_22
      pnpm
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
      pandoc
      pdftk
      postgresql_16
      poppler-utils
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
