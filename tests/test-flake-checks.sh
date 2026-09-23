#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

checks="$(nix eval --json "path:$repo_root#checks.aarch64-darwin" \
  --apply 'builtins.attrNames')" \
  || fail "flake exposes checks for the primary system"

for check in home-manager-build nix-format shell-syntax repository-tests; do
  grep -Fq "\"$check\"" <<<"$checks" \
    || fail "flake checks include $check"
done

for workflow in build lint diff; do
  workflow_file="$repo_root/.github/workflows/$workflow.yaml"
  grep -Fq 'nix flake check --all-systems' "$workflow_file" \
    || fail "$workflow workflow delegates validation to flake checks"
done

if grep -Fq 'nix run nixpkgs#nixfmt' "$repo_root/.github/workflows/lint.yaml"; then
  fail "lint workflow does not duplicate Nix formatting logic"
fi

if grep -Fq '#build' "$repo_root/.github/workflows/build.yaml"; then
  fail "build workflow uses the shared flake checks"
fi

printf 'ok: flake checks tests\n'
