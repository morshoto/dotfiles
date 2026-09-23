#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq './scripts/bootstrap' "$repo_root/README.md" || fail "README documents bootstrap"
grep -Fq 'darwin-switch' "$repo_root/README.md" || fail "README documents Darwin apply"
grep -Fq 'generic-darwin' "$repo_root/README.md" || fail "README documents host outputs"
grep -Fq 'nix/hosts/<name>.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain adding a host"
grep -Fq 'nix/local.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain local configuration"

printf 'ok: documentation tests\n'
