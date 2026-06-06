# Repo Notes

- The repo target is `aarch64-darwin`.
- The primary Home Manager configuration target is `homeConfigurations.apple-silicon`.
- `homeConfigurations.default` remains as a compatibility alias.
- This repo reads machine-specific values from `nix/hosts/apple-silicon.nix`.
- `dotfilesDir` in the host definition is the source of truth for out-of-store
  symlinks to `codex/skills`, `claude/skills`, `fish`, and `zsh`.
- `home.packages` is the canonical CLI package list. The `dotfiles-pkg` flake
  package is retained as a compatibility bundle for `nix profile` workflows.
- `nix-darwin` is intentionally not included yet.
