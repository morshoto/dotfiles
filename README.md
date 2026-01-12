# nix-cli

A personal, reproducible CLI toolchain managed with **Nix flakes** for macOS (Apple Silicon / `aarch64-darwin`).

This repository provides:

-   A **stable, reproducible set of CLI tools** via `nix profile`
-   A **separate development shell** (`nix develop`) for build-time dependencies (C/C++ headers, PostgreSQL dev files, etc.)
-   A small **update workflow** to keep dependencies fresh via `nix flake update`

## ✨ Features

-   Declarative CLI environment (like a reproducible Homebrew bundle)
-   Clear separation between:

    -   **Daily CLI tools** (profile install)
    -   **Build / compilation tools** (devShell only)

-   PostgreSQL `pg_config` shim for consistent native extension builds
-   Fully flake-based (no legacy `nix-shell`)

## Common commands

```bash
# Install tools globally
nix profile add .#my-packages
# Update dependencies
nix run .#update
# Enter build environment
nix develop
# Show flake outputs
nix flake show
# Check installed profile
nix profile list
```

> [!NOTE]
> This flake currently targets only `aarch64-darwin` (Apple Silicon macOS)

## License

Personal configuration. Use freely at your own risk.
