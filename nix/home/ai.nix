{ config, homeDirectory, ... }:

let
  dotfilesDir = "${homeDirectory}/Engineering/dotfiles";
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".codex/config.toml".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/config.toml";

  home.file.".codex/AGENTS.md".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/AGENTS.md";

  home.file.".codex/rules".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/rules";

  home.file.".codex/skills".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/skills";

  home.file.".config/claude/skills".source =
    mkOutOfStoreSymlink "${dotfilesDir}/claude/skills";
}
