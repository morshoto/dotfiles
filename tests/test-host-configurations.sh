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

dotfiles_dir_type="$(nix eval --raw --impure --expr "builtins.typeOf (import \"$repo_root/nix/hosts/default.nix\").apple-silicon.dotfilesDir")"
[[ "$dotfiles_dir_type" == path ]] \
  || fail "host dotfilesDir retains path context for Home Manager symlink derivations"

activation_warnings="$(nix eval --show-trace --raw "path:$repo_root#homeConfigurations.default.activationPackage.drvPath" 2>&1 >/dev/null)" \
  || fail "Home Manager activation derivation evaluates"
if grep -Fq "derivation named 'hm_" <<<"$activation_warnings"; then
  fail "Home Manager symlink derivations retain their store path context"
fi

printf 'ok: host configuration tests\n'
