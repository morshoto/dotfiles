# Repo Notes

- The repo target is `aarch64-darwin`.
- The Home Manager user is `shotomorisaki`.
- This repo assumes it lives at `~/Engineering/dotfiles` so that out-of-store
  symlinks for `codex/skills`, `claude/skills`, `fish`, `zsh`, and `git` resolve
  to the live working tree.
- `home.packages` is the canonical CLI package list. The `morshoto-pkg` flake
  package is retained as a compatibility bundle for `nix profile` workflows.
- `nix-darwin` is intentionally not included yet.
