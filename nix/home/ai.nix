{ config, dotfilesDir, ... }:

let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.file.".codex/config.toml".source = mkOutOfStoreSymlink "${dotfilesDir}/codex/config.toml";

  home.file.".codex/AGENTS.md".source = mkOutOfStoreSymlink "${dotfilesDir}/codex/AGENTS.md";

  # Manage shared rule files inside the existing directory so local-only rules
  # can coexist without Home Manager needing to replace ~/.codex/rules itself.
  home.file.".codex/rules/README.md".source =
    mkOutOfStoreSymlink "${dotfilesDir}/codex/rules/README.md";

  home.file.".codex/skills".source = mkOutOfStoreSymlink "${dotfilesDir}/ai/skills";

  # Codex and Claude Code share the same skill set from ai/skills.
  home.file.".claude/skills".source = mkOutOfStoreSymlink "${dotfilesDir}/ai/skills";
}
