{ ... }:

{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./git.nix
    ./shell.nix
    ./ai.nix
  ];

  programs.home-manager.enable = true;
}
