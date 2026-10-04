# Nix Flake Commands

Run these commands from the repository root. The examples use `path:$PWD` so
Nix evaluates the current working tree, including local edits, rather than only
the Git snapshot. The shorter `nix run .#switch` form is also available from
the repository root.

## Inspect and validate

| Command | Purpose |
| --- | --- |
| `nix run "path:$PWD#help"` | List the available `nix run` commands and their purposes. |
| `nix flake show "path:$PWD"` | List the outputs exposed by this flake. |
| `nix flake check --all-systems "path:$PWD"` | Evaluate and run the flake checks for all supported systems. |
| `nix run "path:$PWD#check"` | Run the flake checks for the current system. |
| `nix run "path:$PWD#check" -- --all-systems` | Run the flake checks for all supported systems through the app. |
| `nix run "path:$PWD#build"` | Build the Home Manager generation without activating it. |

## Apply configuration

| Command | Purpose |
| --- | --- |
| `nix run "path:$PWD#switch"` | Apply the Home Manager configuration for the current user with English live progress and the unread-news count when available. Existing files and conflicting skill-directory symlinks are preserved with an `hm-backup` suffix; full activation details are shown if the switch fails. |
| `nix run "path:$PWD#darwin-switch"` | Apply nix-darwin system settings and Home Manager; this command uses `sudo`. |
| `./scripts/bootstrap` | Set up a fresh supported Apple Silicon Mac and apply its Home Manager configuration. |

## Maintain the flake

| Command | Purpose |
| --- | --- |
| `nix run "path:$PWD#fmt"` | Format Nix files below the current directory. Add `-- --check` to check formatting without writing changes. |
| `nix flake update --flake "path:$PWD"` | Update the locked flake inputs without applying the configuration. |
| `nix run "path:$PWD#update"` | Update flake inputs, list changed inputs with their old and new revisions, then apply the Home Manager configuration. This modifies `flake.lock` and may change installed packages. |
| `nix develop "path:$PWD"` | Enter the repository's development shell. |
| `nix profile add "path:$PWD#dotfiles-pkg"` | Install the compatibility package into a Nix profile. Home Manager is the primary package manager for this repository. |

## Warnings

The tracked host keeps `dotfilesDir` as a path value so Home Manager's
out-of-store symlink derivations retain the required store context. The
remaining `builtins.derivation` warning for `options.json` comes from the
Nixpkgs option-docs builder (`nixpkgs` input,
`nixos/lib/make-options-doc/default.nix`), evaluated as part of Home Manager's
option docs. Its generated derivation refers to the Nixpkgs source without
preserving the required store context. Fixing that requires an upstream
Nixpkgs change or a local fork/override; this repo does not suppress the
warning. A warning alone does not mean the check failed: confirm that the
command exits successfully and the checks report success.
