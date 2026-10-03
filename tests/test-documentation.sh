#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

grep -Fq './scripts/bootstrap' "$repo_root/README.md" || fail "README documents bootstrap"
grep -Fq 'darwin-switch' "$repo_root/README.md" || fail "README documents Darwin apply"
grep -Fq '`apple-silicon`' "$repo_root/README.md" || fail "README documents the supported host"
grep -Fq 'aarch64-darwin' "$repo_root/README.md" || fail "README documents the host architecture"
if grep -Fq 'generic-darwin' "$repo_root/README.md" \
  || grep -Fq 'generic-darwin' "$repo_root/doc/nix-install.md"; then
  fail "user documentation does not advertise a duplicate host"
fi
grep -Fq 'nix/hosts/<name>.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain adding a host"
grep -Fq 'nix/local.nix' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain local configuration"
grep -Fq 'hostName' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain local host selection"
grep -Fq 'username' "$repo_root/doc/nix-install.md" \
  || fail "install docs explain local user overrides"

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

printf 'ok: documentation tests\n'
