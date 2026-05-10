# Install and Switching

This repo is primarily applied through Home Manager.

## Apply the configuration

From the repo root:

```sh
nix run .#switch
```

This runs Home Manager for `shotomorisaki` and applies:

- CLI packages from `home.packages`
- Git and shell settings
- repo-backed symlinks for Codex and Claude skills

## Compatibility profile install

If you only want the CLI bundle without the rest of the dotfiles config:

```sh
nix profile add .#morshoto-pkg
```

This compatibility bundle remains available, but `home.packages` is the primary
source of truth.

## Development shell

Use the development shell for build-time dependencies such as PostgreSQL headers,
LLVM, `pkg-config`, and the `pg_config` shim:

```sh
nix develop
```

## Validation

Inspect the outputs:

```sh
nix flake show
```

Build the Home Manager configuration without switching:

```sh
nix build .#homeConfigurations.shotomorisaki.activationPackage
```
