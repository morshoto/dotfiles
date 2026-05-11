{ config, dotfilesDir, ... }:

let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.enable = true;

  home.file.".config/zsh".source = mkOutOfStoreSymlink "${dotfilesDir}/zsh";
  home.file.".config/fish".source = mkOutOfStoreSymlink "${dotfilesDir}/fish";
}
