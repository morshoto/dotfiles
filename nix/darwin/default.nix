{ ... }:

{
  system.stateVersion = 4;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;

  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  system.defaults.dock.autohide = true;
}
