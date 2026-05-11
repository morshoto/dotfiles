# Missing Package Troubleshooting

If a package seems missing after `nix run "path:$PWD#switch"`, build the activation package
first to confirm the configuration evaluates:

```sh
nix run "path:$PWD#build"
```

If you are using the compatibility profile bundle instead, verify the package is
in the bundle closure:

```sh
nix path-info -r "path:$PWD#morshoto-pkg" | rg '<package>'
```

For a package added to the compatibility bundle, reinstall it:

```sh
nix profile add "path:$PWD#morshoto-pkg"
```

If a command still resolves to an unexpected binary, reload the shell:

```sh
exec zsh
```
