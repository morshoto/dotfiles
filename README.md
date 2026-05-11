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
nix run "path:$PWD#switch"

# Build the Home Manager config without switching
nix run "path:$PWD#build"

# Update flake inputs, then re-apply the config
nix run "path:$PWD#update"

# Run flake checks
nix run "path:$PWD#check"

# Format Nix files
nix run "path:$PWD#fmt"

# Enter the development shell
nix develop "path:$PWD"

# Show flake outputs
nix flake show "path:$PWD"

# Compatibility install for profile-based usage
nix profile add "path:$PWD#morshoto-pkg"
```

## Layout

```txt
.
├── flake.nix
├── nix/
│   ├── apps.nix
│   ├── devshell.nix
│   ├── hosts/
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

- The primary Home Manager target is `homeConfigurations.apple-silicon`.
- `homeConfigurations.default` is kept as a temporary alias for compatibility.
- Machine-specific values live in the tracked host definition at
  `nix/hosts/apple-silicon.nix`.
- Flake commands use `path:$PWD` from the repo root so Nix evaluates the live
  working tree instead of the Git snapshot.
- Skills are linked from this repo using out-of-store symlinks, so edits here apply
  directly after `nix run "path:$PWD#switch"`.
- `morshoto-pkg` remains available for `nix profile` compatibility, but
  `home.packages` is the primary source of truth.

## Docs

- [Install and switching](doc/nix-install.md)
- [Update flow](doc/update.md)
- [Repo notes](doc/notes.md)
