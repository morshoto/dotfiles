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

# Bootstrap a fresh Apple Silicon Mac
./scripts/bootstrap

# Apply macOS system settings and Home Manager
nix run "path:$PWD#darwin-switch"

# Build the Home Manager config without switching
nix run "path:$PWD#build"

# Update flake inputs, then re-apply the config
nix run "path:$PWD#update"

# Run all flake checks locally
nix flake check --all-systems "path:$PWD"

# Format Nix files
nix run "path:$PWD#fmt"

# Enter the development shell
nix develop "path:$PWD"

# Show flake outputs
nix flake show "path:$PWD"

# Compatibility install for profile-based usage
nix profile add "path:$PWD#dotfiles-pkg"
```

## Codex model selection

After applying the Home Manager configuration, choose Astra for a session with:

```bash
codex -m gpt-6-astra
```

## Layout

```txt
.
├── .github/
├── ai/
│   └── skills/
├── codex/
│   └── rules/
├── doc/
├── fish/
├── ghostty/
├── git/
├── nix/
├── scripts/
├── tests/
├── zsh/
└── flake.nix
```

## Notes

- Home Manager exposes `apple-silicon` and `generic-darwin` host targets.
- `homeConfigurations.default` follows the host selected in `nix/local.nix`.
- nix-darwin exposes the same host names under `darwinConfigurations`.
- Machine-specific values live in the tracked host definition at
  `nix/hosts/<name>.nix`, with local overrides in ignored `nix/local.nix`.
- Flake commands use `path:$PWD` from the repo root so Nix evaluates the live
  working tree instead of the Git snapshot.
- Shared skills live in `ai/skills` and are linked to both `~/.codex/skills` and
  `~/.claude/skills` using out-of-store symlinks, so edits here apply directly
  after `nix run "path:$PWD#switch"`.
- Codex-specific instructions and rules remain under `codex/`; private
  authentication and session data stay outside the repository.
- `dotfiles-pkg` remains available for `nix profile` compatibility, but
  `home.packages` is the primary source of truth.

## Docs

- [Install and switching](doc/nix-install.md)
- [Update flow](doc/update.md)
- [Repo notes](doc/notes.md)
