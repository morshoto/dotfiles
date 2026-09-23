#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
blocked_files="$({
  cd "$repo_root"
  git ls-files | grep -En '(^|/)(\.env($|\.)|.*\.(pem|key|p12|pfx|jks|kdbx)$|codex/auth\.json$|nix/local\.nix$)' || true
})"

if [[ -n "$blocked_files" ]]; then
  printf '%s\n' "$blocked_files"
  printf 'Found tracked sensitive filenames.\n' >&2
  exit 1
fi
