# Install and Switching

This repo can be applied through Home Manager alone or through nix-darwin for
macOS system settings plus Home Manager.

## Fresh Apple Silicon Mac

Install Xcode Command Line Tools and Nix interactively, then run the bootstrap
entry point from a checkout (or from a copied `scripts/bootstrap`):

```sh
./scripts/bootstrap
```

The script locates or clones the repository, creates the ignored
`nix/local.nix` from `nix/local.example.nix` when needed, and applies the
Home Manager configuration. It never stores credentials. Set
`DOTFILES_REPO_DIR`, `DOTFILES_REPO_URL`, `DOTFILES_HOST`, `DOTFILES_USERNAME`,
or `DOTFILES_HOME` to override its defaults. Use `--dry-run` to inspect the
final apply command without running it.

## Apply the configuration

From the repo root:

```sh
nix run "path:$PWD#switch"
```

This runs Home Manager for the current user and applies:

- CLI packages from `home.packages`
- Git and shell settings
- repo-backed symlinks for Codex and Claude skills

## Apply macOS system configuration

The nix-darwin target includes a small initial set of system defaults and the
same Home Manager modules:

```sh
nix run "path:$PWD#darwin-switch"
```

This invokes `darwin-rebuild switch` through the pinned nix-darwin input and
will request administrator authentication.

## Add another host

1. Add explicit `system`, `username`, `homeDirectory`, and `dotfilesDir`
   values to `nix/hosts/<name>.nix`.
2. Register that file in `nix/hosts/default.nix`.
3. Set `hostName = "<name>"` in your ignored `nix/local.nix` if it is the
   active machine.
4. Validate both outputs:

   ```sh
   nix flake check --all-systems "path:$PWD"
   nix flake show "path:$PWD"
   ```

The shared Home Manager modules are reused automatically; no flake changes are
needed for a new host after it is registered in the host map.

## Compatibility profile install

If you only want the CLI bundle without the rest of the dotfiles config:

```sh
nix profile add "path:$PWD#dotfiles-pkg"
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
