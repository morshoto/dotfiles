#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

flake_commands="$repo_root/doc/nix-flake-commands.md"
[[ -f "$flake_commands" ]] || fail "Nix flake command reference exists"
grep -Fq '[Nix flake commands](doc/nix-flake-commands.md)' \
  "$repo_root/README.md" || fail "README links Nix flake commands"
for command in \
  'nix flake check --all-systems "path:$PWD"' \
  'nix run "path:$PWD#check" -- --all-systems' \
  'nix run "path:$PWD#build"' \
  'nix run "path:$PWD#help"' \
  'nix run "path:$PWD#switch"' \
  'nix run "path:$PWD#darwin-switch"' \
  'nix run "path:$PWD#fmt"' \
  'nix run "path:$PWD#update"' \
  'nix develop "path:$PWD"' \
  'nix flake show "path:$PWD"'; do
  grep -Fq "$command" "$flake_commands" || fail "Nix command reference includes $command"
done
grep -Fq 'builtins.derivation' "$flake_commands" \
  || fail "Nix command reference explains the known warning"
grep -Fq 'options.json' "$flake_commands" \
  || fail "Nix command reference identifies the upstream options.json warning"
grep -Fq 'nixos/lib/make-options-doc/default.nix' "$flake_commands" \
  || fail "Nix command reference points to the upstream warning source"

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

inventory="$repo_root/doc/settings-inventory.md"
[[ -f "$inventory" ]] || fail "settings inventory exists"
grep -Fq '[Configuration inventory and scope](doc/settings-inventory.md)' \
  "$repo_root/README.md" || fail "README links the settings inventory"
grep -Fq '## Currently managed' "$inventory" \
  || fail "inventory names managed settings"
grep -Fq '## Intentionally local' "$inventory" \
  || fail "inventory names local settings"
grep -Fq '## Candidate decisions' "$inventory" \
  || fail "inventory records candidate decisions"

for decision in \
  '| Powerlevel10k | Include |' \
  '| GitHub CLI (`gh`) | Defer |' \
  '| VS Code settings and keybindings | Defer |' \
  '| Additional macOS defaults | Defer |'; do
  grep -Fq "$decision" "$inventory" \
    || fail "inventory records decision: $decision"
done

grep -Fq 'zsh/p10k.zsh' "$inventory" \
  || fail "inventory names the Powerlevel10k source of truth"
grep -Fq 'nix run "path:$PWD#switch"' "$inventory" \
  || fail "inventory explains how to apply selected settings"
grep -Fq '~/.config/gh/hosts.yml' "$inventory" \
  || fail "inventory keeps GitHub CLI credentials local"
grep -Fq 'mcp.json' "$inventory" \
  || fail "inventory keeps VS Code MCP state local"
grep -Fq 'chatLanguageModels.json' "$inventory" \
  || fail "inventory keeps VS Code model state local"

[[ -f "$repo_root/zsh/p10k.zsh" ]] \
  || fail "Powerlevel10k config has a repository source"
grep -Fq 'home.file.".p10k.zsh".source' "$repo_root/nix/home/dotfiles.nix" \
  || fail "Home Manager applies the Powerlevel10k config"
if grep -Eq 'Google application credentials|deathray-testing' "$repo_root/zsh/p10k.zsh"; then
  fail "Powerlevel10k config excludes local credential examples"
fi
if grep -REq 'home\.file\..*(gh/hosts\.yml|mcp\.json|chatLanguageModels\.json)' \
  "$repo_root/nix/home"; then
  fail "Home Manager does not import private application state"
fi

printf 'ok: documentation tests\n'
