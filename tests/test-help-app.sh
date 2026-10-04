#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apps_file="$repo_root/nix/apps.nix"
help_script="$repo_root/scripts/apps/help.sh"
command_docs="$repo_root/doc/nix-flake-commands.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -f "$help_script" ]] || fail "help app script exists"
grep -Fq 'mkScript "help" ../scripts/apps/help.sh' "$apps_file" \
  || fail "flake help app uses scripts/apps/help.sh"
grep -Fq 'APP_COMMANDS' "$help_script" \
  || fail "help output receives the flake command list"
grep -Fq 'appDescriptions.${name}' "$apps_file" \
  || fail "help output is generated from app descriptions"

commands="$(sed -n '/^  appDescriptions = {/,/^  };/p' "$apps_file" \
  | sed -nE 's/^    ([[:alnum:]-]+) = "([^"]*)";$/\1\t\2/p')"
[[ -n "$commands" ]] || fail "flake command descriptions exist"
while IFS=$'\t' read -r command description; do
  [[ -n "$command" && -n "$description" ]] || fail "flake command has a description"
  grep -Fq "#$command" "$command_docs" \
    || fail "command documentation includes $command"
done <<< "$commands"

printf 'ok: Nix help app tests\n'
