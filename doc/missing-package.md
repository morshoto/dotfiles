# Missing Package Troubleshooting

If a package seems missing after `nix run --impure .#switch`, build the activation package
first to confirm the configuration evaluates:

```sh
nix build --impure .#homeConfigurations.default.activationPackage
```

If you are using the compatibility profile bundle instead, verify the package is
in the bundle closure:

```sh
nix path-info -r .#morshoto-pkg | rg '<package>'
```

For a package added to the compatibility bundle, reinstall it:

```sh
nix profile add .#morshoto-pkg
```

If a command still resolves to an unexpected binary, reload the shell:

```sh
exec zsh
```
