# Update Flow

Update flake inputs and immediately re-apply the Home Manager configuration:

```sh
nix run "path:$PWD#update"
```

The app performs:

```sh
nix flake update --flake "path:$PWD"
nix run "path:$PWD#switch"
```

If you want to review lockfile changes before switching, run the steps manually:

```sh
nix flake update --flake "path:$PWD"
nix run "path:$PWD#build"
git diff -- flake.lock
```

The `dotfiles-pkg` compatibility bundle contains the same commands as
Home Manager. Use one installation method at a time: adding the bundle to the
profile managed by Home Manager can create file conflicts.

If you use the profile bundle instead of Home Manager, install it once with:

```sh
nix profile install "path:$PWD#dotfiles-pkg"
```

After updating `flake.lock`, refresh that existing profile entry with:

```sh
nix profile upgrade dotfiles-pkg
```
