#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v gitleaks >/dev/null 2>&1; then
  printf 'gitleaks is required; run this from `nix develop`.\n' >&2
  exit 2
fi

fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name test

access_key_prefix='AKIA'
access_key_suffix='0123456789ABCDEF'
printf 'AWS_ACCESS_KEY_ID=%s%s\n' "$access_key_prefix" "$access_key_suffix" >"$fixture/config.env"

if gitleaks detect \
  --source "$fixture" \
  --no-git \
  --redact \
  --no-banner \
  --config "$repo_root/.gitleaks.toml"; then
  printf 'FAIL: gitleaks did not detect the deliberately introduced test secret\n' >&2
  exit 1
fi

printf 'ok: generic secret detection test\n'
