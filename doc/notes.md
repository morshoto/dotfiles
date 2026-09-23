# Repo Notes

- The repo target is `aarch64-darwin`.
- The primary Home Manager configuration target is `homeConfigurations.apple-silicon`.
- `homeConfigurations.default` remains as a compatibility alias.
- This repo reads machine-specific values from `nix/hosts/apple-silicon.nix`.
- `dotfilesDir` in the host definition is the source of truth for out-of-store
  symlinks to `ai/skills`, `fish`, and `zsh`; the shared skills are linked to
  both Codex and Claude Code home directories.
- `home.packages` is the canonical CLI package list. The `dotfiles-pkg` flake
  package is retained as a compatibility bundle for `nix profile` workflows.
- `nix-darwin` is intentionally not included yet.
