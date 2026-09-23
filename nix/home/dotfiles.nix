{ config, dotfilesDir, ... }:

let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.enable = true;

  home.file.".config/zsh".source = mkOutOfStoreSymlink "${dotfilesDir}/zsh";
  home.file.".config/fish".source = mkOutOfStoreSymlink "${dotfilesDir}/fish";
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    mkOutOfStoreSymlink "${dotfilesDir}/ghostty/config";
}
