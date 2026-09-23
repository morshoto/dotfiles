#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$repo_root/nix/hosts/apple-silicon.nix" ]] || fail "Apple Silicon host exists"
[[ -f "$repo_root/nix/hosts/generic-darwin.nix" ]] || fail "generic Darwin host exists"
grep -Fq 'hostName' "$repo_root/nix/local.example.nix" || fail "local example selects a host"

home_hosts="$(nix eval --json "path:$repo_root#homeConfigurations" --apply 'builtins.attrNames')"
grep -Fq 'apple-silicon' <<<"$home_hosts" || fail "Apple Silicon Home Manager output exists"
grep -Fq 'generic-darwin' <<<"$home_hosts" || fail "generic Darwin Home Manager output exists"

darwin_hosts="$(nix eval --json "path:$repo_root#darwinConfigurations" --apply 'builtins.attrNames')"
grep -Fq 'apple-silicon' <<<"$darwin_hosts" || fail "Apple Silicon Darwin output exists"
grep -Fq 'generic-darwin' <<<"$darwin_hosts" || fail "generic Darwin Darwin output exists"

printf 'ok: host configuration tests\n'
