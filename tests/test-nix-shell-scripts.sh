#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

for file in \
  scripts/apps/build.sh \
  scripts/apps/check.sh \
  scripts/apps/darwin-switch.sh \
  scripts/apps/fmt.sh \
  scripts/apps/switch.sh \
  scripts/apps/update.sh \
  scripts/install-agent-browser.sh \
  scripts/nix-format-check.sh \
  scripts/pg-config.sh \
  scripts/repository-tests.sh \
  scripts/shell-syntax-check.sh; do
  [[ -f "$repo_root/$file" ]] || fail "shell implementation lives in $file"
done

for script in build check darwin-switch fmt switch update; do
  grep -Fq "builtins.readFile ../scripts/apps/$script.sh" "$repo_root/nix/apps.nix" \
    || fail "Nix app reads scripts/apps/$script.sh"
done

grep -Fq 'builtins.readFile ../scripts/pg-config.sh' "$repo_root/nix/devshell.nix" \
  || fail "dev shell reads scripts/pg-config.sh"
grep -Fq 'builtins.readFile ../scripts/install-agent-browser.sh' "$repo_root/nix/packages.nix" \
  || fail "package phase reads scripts/install-agent-browser.sh"

for script in nix-format-check repository-tests shell-syntax-check; do
  grep -Fq "builtins.readFile ./scripts/$script.sh" "$repo_root/flake.nix" \
    || fail "flake check reads scripts/$script.sh"
done

while IFS= read -r nix_file; do
  if grep -Fq "''" "$nix_file"; then
    fail "shell blocks live outside $nix_file"
  fi
done < <(find "$repo_root" -type f -name '*.nix' -print)

printf 'ok: shell scripts are kept in .sh files\n'
