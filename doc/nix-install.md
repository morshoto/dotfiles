# Install and Switching

This repo is primarily applied through Home Manager.

The tracked host definition for this machine lives at
`nix/hosts/apple-silicon.nix`.

## Apply the configuration

From the repo root:

```sh
nix run "path:$PWD#switch"
```

This runs Home Manager for the current user and applies:

- CLI packages from `home.packages`
- Git and shell settings
- repo-backed symlinks for Codex and Claude skills

## Compatibility profile install

If you only want the CLI bundle without the rest of the dotfiles config:

```sh
nix profile add "path:$PWD#morshoto-pkg"
```

This compatibility bundle remains available, but `home.packages` is the primary
source of truth.

## Development shell

Use the development shell for build-time dependencies such as PostgreSQL headers,
LLVM, `pkg-config`, and the `pg_config` shim:

```sh
nix develop "path:$PWD"
```

## Validation

Inspect the outputs:

```sh
nix flake show "path:$PWD"
```

Build the Home Manager configuration without switching:

```sh
nix run "path:$PWD#build"
```

## Why `path:$PWD`

When a flake is referenced as `.` inside a Git repo, Nix evaluates the Git
snapshot. Using `path:$PWD` makes Nix evaluate the live working tree instead,
which is useful while iterating on uncommitted changes.
