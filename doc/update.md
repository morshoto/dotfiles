# Update Flow

Update flake inputs and immediately re-apply the Home Manager configuration:

```sh
nix run .#update
```

The app performs:

```sh
nix flake update --flake .
nix run .#switch
```

If you want to review lockfile changes before switching, run the steps manually:

```sh
nix flake update --flake .
nix build .#homeConfigurations.shotomorisaki.activationPackage
git diff -- flake.lock
```

If you still rely on the compatibility profile bundle, refresh it explicitly:

```sh
nix profile add .#morshoto-pkg
```
