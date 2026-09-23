#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -d "$repo_root/ai/skills" ]] || fail "shared AI skills have a neutral source"
[[ ! -d "$repo_root/codex/skills" ]] || fail "Codex does not own shared skills"

grep -Fq '".codex/skills"' "$repo_root/nix/home/ai.nix" \
  || fail "Home Manager links Codex skills"
grep -Fq '".claude/skills"' "$repo_root/nix/home/ai.nix" \
  || fail "Home Manager links Claude skills"
grep -Fq '"${dotfilesDir}/ai/skills"' "$repo_root/nix/home/ai.nix" \
  || fail "both tool links use the neutral source"

[[ -f "$repo_root/codex/AGENTS.md" ]] || fail "Codex-specific instructions remain"
[[ -f "$repo_root/codex/rules/README.md" ]] || fail "Codex-specific rules remain"
[[ -f "$repo_root/ai/README.md" ]] || fail "shared AI layout is documented"

if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  && git -C "$repo_root" ls-files --error-unmatch codex/config.toml >/dev/null 2>&1; then
  fail "Codex auth configuration is not tracked"
fi

printf 'ok: shared AI configuration tests\n'
