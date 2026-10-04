#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq './scripts/bootstrap' "$repo_root/README.md" || fail "README documents bootstrap"
grep -Fq 'darwin-switch' "$repo_root/README.md" || fail "README documents Darwin apply"
grep -Fq 'generic-darwin' "$repo_root/README.md" || fail "README documents host outputs"
grep -Fq 'nix/hosts/<name>.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain adding a host"
grep -Fq 'nix/local.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain local configuration"

layout="$(sed -n '/^## Layout$/,/^## Notes$/p' "$repo_root/README.md")"
for entry in ai codex doc fish git ghostty nix scripts tests zsh; do
  grep -Fq "├── $entry/" <<<"$layout" \
    || fail "README layout includes $entry"
done

if grep -Fq 'claude/skills/' <<<"$layout" || grep -Fq 'codex/skills/' <<<"$layout"; then
  fail "README layout does not list stale skill directories"
fi

grep -Fq 'ai/skills' "$repo_root/README.md" \
  || fail "README explains the shared skill source"
grep -Fq '~/.claude/skills' "$repo_root/README.md" \
  || fail "README explains the Claude skill link"

grep -Fq 'nix-darwin' "$repo_root/doc/notes.md" \
  || fail "repo notes document nix-darwin"
grep -Fq 'darwinConfigurations' "$repo_root/doc/notes.md" \
  || fail "repo notes describe Darwin outputs"
grep -Fq 'darwin-switch' "$repo_root/doc/notes.md" \
  || fail "repo notes describe Darwin apply"
if grep -Fq 'nix-darwin is intentionally not included yet' "$repo_root/doc/notes.md"; then
  fail "repo notes do not claim nix-darwin is absent"
fi

printf 'ok: documentation tests\n'
