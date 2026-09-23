#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflow="$repo_root/.github/workflows/update-flake-lock.yaml"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$workflow" ]] || fail "flake update workflow exists"
grep -Eq '^  schedule:' "$workflow" || fail "workflow has a schedule"
grep -Eq '^  workflow_dispatch:' "$workflow" || fail "workflow supports manual dispatch"
grep -Fq 'nix flake update --flake' "$workflow" || fail "workflow updates flake.lock"
grep -Fq 'nix flake check --all-systems' "$workflow" || fail "workflow runs flake checks"
grep -Fq '#build' "$workflow" || fail "workflow builds Home Manager"
grep -Fq 'peter-evans/create-pull-request@v7' "$workflow" || fail "workflow opens update PRs"
grep -Fq 'add-paths: flake.lock' "$workflow" || fail "workflow limits PR changes to flake.lock"
if grep -Fq '#switch' "$workflow" || grep -Fq 'home-manager switch' "$workflow"; then
  fail "workflow never switches the CI environment"
fi

printf 'ok: flake update workflow tests\n'
