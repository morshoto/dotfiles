
```bash
nix profile remove morshoto-pkg || true
nix profile add --profile ~/.nix-profile .#morshoto-pkg
hash -r
node -v
pnpm -v
```

if `error: An existing package already provides the following file`

```bash
nix profile remove --profile ~/.nix-profile nix-cli
```
