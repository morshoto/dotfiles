# Scripts

Put helper scripts for this dotfiles repo here when needed.

## Security validation

Run the filename check from the repository root:

```sh
./scripts/check-sensitive-files.sh
```

Run the generic secret-detection regression test from the development shell:

```sh
nix develop "path:$PWD"
./scripts/test-sensitive-scan.sh
```

The test creates a temporary AWS-shaped credential and verifies that Gitleaks
rejects it. The temporary fixture is removed when the test exits.
