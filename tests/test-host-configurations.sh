#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$repo_root/nix/hosts/apple-silicon.nix" ]] || fail "Apple Silicon host exists"
[[ ! -e "$repo_root/nix/hosts/generic-darwin.nix" ]] || fail "duplicate generic Darwin host is removed"
grep -Fq 'hostName' "$repo_root/nix/local.example.nix" || fail "local example selects a host"

home_hosts="$(nix eval --json "path:$repo_root#homeConfigurations" --apply 'builtins.attrNames')"
[[ "$home_hosts" == '["apple-silicon","default"]' ]] \
  || fail "Home Manager exposes the supported target and default alias"

apple_system="$(nix eval --raw "path:$repo_root#homeConfigurations.apple-silicon.pkgs.stdenv.hostPlatform.system")"
[[ "$apple_system" == "aarch64-darwin" ]] || fail "Apple Silicon host targets aarch64-darwin"

printf 'ok: host configuration tests\n'
