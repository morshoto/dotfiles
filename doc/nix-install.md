# Installing Packages with Nix (This Repo)

This repo exposes a single package bundle via the flake output `morshoto-pkg`.
Installing it adds all packages listed in `flake.nix` to your Nix profile.

## Install the bundle

Run from the repo root:

```sh
nix profile add .#morshoto-pkg
```

Notes:

- `nix profile install` is a deprecated alias of `add`.
- You can target a specific profile if needed:

```sh
nix profile add --profile ~/.nix-profile --priority 50 .#morshoto-pkg
```

## Update after editing `flake.nix`

If you add/remove packages in `flake.nix`, re-run the install command to refresh your profile:

```sh
nix profile add .#morshoto-pkg
```

## Optional: update flake lock + refresh profile

This repo includes an update app that updates `flake.lock` and reinstalls the profile bundle:

```sh
nix run .#update
```

## Troubleshooting

- If a package name is unknown, search for it first:

```sh
nix search nixpkgs <package>
```

- If `nix profile add` says the package is already added, the profile is already up to date.

## Validation

Because `openmp` is a runtime library (no CLI binary), validate it via the package closure:

```sh
nix path-info -r .#morshoto-pkg | rg -i 'openmp|libomp|omp'
```

For a quick yes/no check:

```sh
nix path-info -r .#morshoto-pkg | rg -q 'openmp-' && echo "openmp present"
```
