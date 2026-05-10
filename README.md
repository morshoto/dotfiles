# dotfiles

Personal dotfiles and CLI tooling managed with Nix flakes on macOS Apple Silicon
(`aarch64-darwin`).

This repo now manages:

- CLI packages via Home Manager and a compatibility bundle
- Development-only build tooling via `nix develop`
- Git and shell settings
- Codex / Claude skills via repo-backed symlinks

## Common commands

```bash
# Apply this repo to the current user
nix run .#switch

# Update flake inputs, then re-apply the config
nix run .#update

# Enter the development shell
nix develop

# Show flake outputs
nix flake show

# Compatibility install for profile-based usage
nix profile add .#morshoto-pkg
```

## Layout

```txt
.
├── flake.nix
├── nix/
│   ├── apps.nix
│   ├── devshell.nix
│   ├── packages.nix
│   └── home/
├── codex/skills/
├── claude/skills/
├── fish/
├── zsh/
├── git/
└── scripts/
```

## Notes

- The Home Manager target is `shotomorisaki`.
- Skills are linked from this repo using out-of-store symlinks, so edits here apply
  directly after `nix run .#switch`.
- `morshoto-pkg` remains available for `nix profile` compatibility, but
  `home.packages` is the primary source of truth.

## Docs

- [Install and switching](doc/nix-install.md)
- [Update flow](doc/update.md)
- [Repo notes](doc/notes.md)
