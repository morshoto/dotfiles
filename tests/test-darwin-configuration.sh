#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$repo_root/nix/darwin/default.nix" ]] || fail "Darwin module exists"
grep -Fq 'nix-darwin' "$repo_root/flake.nix" || fail "flake declares nix-darwin"
grep -Fq 'darwinConfigurations' "$repo_root/flake.nix" || fail "flake exposes Darwin configurations"

darwin_hosts="$(nix eval --json "path:$repo_root#darwinConfigurations" --apply 'builtins.attrNames')"
grep -Fq 'apple-silicon' <<<"$darwin_hosts" || fail "Apple Silicon Darwin output exists"
grep -Fq 'generic-darwin' <<<"$darwin_hosts" || fail "generic Darwin Darwin output exists"

grep -Fq 'home-manager.darwinModules.home-manager' "$repo_root/flake.nix" \
  || fail "Darwin configuration integrates Home Manager"

printf 'ok: Darwin configuration tests\n'
