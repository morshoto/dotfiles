{ config, homeDirectory, ... }:

let
  dotfilesDir = "${homeDirectory}/Engineering/dotfiles";
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".codex/skills".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/skills";

  home.file.".config/claude/skills".source =
    mkOutOfStoreSymlink "${dotfilesDir}/claude/skills";
}
