#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scan_script="$repo_root/scripts/check-sensitive-files.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -x "$scan_script" ]] || fail "filename scanner is executable"
grep -Fq 'gitleaks/gitleaks-action' "$repo_root/.github/workflows/sensitive.yaml" \
  || fail "workflow uses a generic secret scanner"
grep -Fq 'scripts/check-sensitive-files.sh' "$repo_root/.github/workflows/sensitive.yaml" \
  || fail "workflow checks blocked filenames"

for personal_identifier in shotomorisaki morshoto jojoto8845 '@icloud.com' '/Users/shotomorisaki'; do
  if grep -Fqi "$personal_identifier" "$repo_root/.github/workflows/sensitive.yaml"; then
    fail "workflow does not contain personal identifier: $personal_identifier"
  fi
done

"$scan_script"

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/nix"
git -C "$fixture" init -q
touch "$fixture/.env"
touch "$fixture/nix/local.nix"
git -C "$fixture" add .env nix/local.nix

if (
  cd "$fixture"
  "$scan_script"
); then
  fail "blocked filenames are rejected"
fi

printf 'ok: sensitive scan tests\n'
