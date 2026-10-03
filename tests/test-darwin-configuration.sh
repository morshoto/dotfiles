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
[[ "$darwin_hosts" == '["apple-silicon"]' ]] \
  || fail "nix-darwin exposes only the supported Apple Silicon target"

apple_system="$(nix eval --raw "path:$repo_root#darwinConfigurations.apple-silicon.pkgs.stdenv.hostPlatform.system")"
[[ "$apple_system" == "aarch64-darwin" ]] || fail "Apple Silicon Darwin target is aarch64-darwin"

grep -Fq 'home-manager.darwinModules.home-manager' "$repo_root/flake.nix" \
  || fail "Darwin configuration integrates Home Manager"
grep -Fq 'darwin-switch' "$repo_root/nix/apps.nix" || fail "Darwin switch app exists"

printf 'ok: Darwin configuration tests\n'
