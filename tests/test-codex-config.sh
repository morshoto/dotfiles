#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

portable_config="$repo_root/codex/portable.config.toml"
[[ -f "$portable_config" ]] || fail "portable Codex profile exists"
git -C "$repo_root" ls-files --error-unmatch codex/portable.config.toml >/dev/null 2>&1 \
  || fail "portable Codex profile is tracked"
[[ -L "$repo_root/.codex/config.toml" ]] \
  || fail "portable settings are available as project configuration"
[[ "$(readlink "$repo_root/.codex/config.toml")" == "../codex/portable.config.toml" ]] \
  || fail "project settings share the portable profile source"

cd "$repo_root"
nix eval --raw --expr '
  let
    config = builtins.fromTOML (builtins.readFile ./codex/portable.config.toml);
    expectedTopLevel = [
      "approval_policy"
      "approvals_reviewer"
      "features"
      "model"
      "model_reasoning_effort"
      "personality"
      "sandbox_mode"
    ];
    expectedFeatures = [
      "codex_git_commit"
      "goals"
      "js_repl"
      "memories"
      "multi_agent"
      "rmcp_client"
    ];
    actualTopLevel = builtins.sort builtins.lessThan (builtins.attrNames config);
    actualFeatures = builtins.sort builtins.lessThan (builtins.attrNames config.features);
  in
    if actualTopLevel != expectedTopLevel then
      throw "portable profile must contain only reviewed portable settings"
    else if actualFeatures != expectedFeatures then
      throw "portable profile feature flags must match the reviewed allowlist"
    else
      "ok"
' >/dev/null || fail "portable profile parses and has only portable keys"

grep -Fq 'config.toml' "$repo_root/codex/.gitignore" \
  || fail "the machine-local Codex config remains ignored"
grep -Fq '".codex/config.toml"' "$repo_root/nix/home/ai.nix" \
  || fail "Home Manager keeps the machine-local config link"
grep -Fq '".codex/portable.config.toml"' "$repo_root/nix/home/ai.nix" \
  || fail "Home Manager links the portable profile"
grep -Fq 'codex --profile portable' "$repo_root/codex/README.md" \
  || fail "Codex docs explain how to apply the portable profile"
grep -Fq 'trusted project' "$repo_root/codex/README.md" \
  || fail "Codex docs explain the trusted project layer"

printf 'ok: Codex configuration tests\n'
