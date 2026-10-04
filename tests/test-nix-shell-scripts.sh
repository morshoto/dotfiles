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
  grep -Fq "mkScript \"$script\" ../scripts/apps/$script.sh" "$repo_root/nix/apps.nix" \
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

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
mock_bin="$test_home/bin"
mkdir -p "$mock_bin" "$test_home/.codex" "$test_home/.claude" "$test_home/old-skills"
ln -s "$test_home/old-skills" "$test_home/.codex/skills"
ln -s "$test_home/old-skills" "$test_home/.claude/skills"
printf 'keep existing backup\n' > "$test_home/.codex/skills.hm-backup"
cat > "$mock_bin/home-manager" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$HOME/home-manager-args"
printf '%s\n' "${LC_ALL:-unset}" > "$HOME/home-manager-locale"
printf 'Verbose activation detail\n'
printf "Existing file '%s/.p10k.zsh' is in the way of '/nix/store/example/.p10k.zsh', will be moved to '%s/.p10k.zsh.hm-backup'\n" \
  "$HOME" "$HOME"
printf 'There are 293 unread news items. Use "home-manager news" to review them.\n'
if [[ "${HOME_MANAGER_FAIL:-0}" == 1 ]]; then
  printf 'Home Manager activation failed\n' >&2
  exit 42
fi
MOCK
chmod +x "$mock_bin/home-manager"

sed \
  -e "s|@HOME_MANAGER_BIN@|$mock_bin/home-manager|g" \
  -e "s|@NIX_STORE_DIR@|$test_home/nix/store|g" \
  -e 's|@FLAKE_REF@|test-flake|g' \
  "$repo_root/scripts/apps/switch.sh" > "$test_home/switch"
chmod +x "$test_home/switch"
HOME="$test_home" "$test_home/switch" --show-trace > "$test_home/switch-output" 2>&1

[[ -L "$test_home/.codex/skills.hm-backup.1" ]] \
  || fail "existing Codex skills directory symlink is preserved without clobbering a backup"
[[ -L "$test_home/.claude/skills.hm-backup" ]] \
  || fail "existing Claude skills directory symlink is preserved"
[[ -d "$test_home/old-skills" ]] \
  || fail "backing up directory symlinks preserves their shared target"
[[ "$(cat "$test_home/.codex/skills.hm-backup")" == 'keep existing backup' ]] \
  || fail "existing backup is not overwritten"
[[ "$(cat "$test_home/home-manager-args")" == 'switch -b hm-backup --impure --flake test-flake --show-trace' ]] \
  || fail "Home Manager switch runs after preserving directory symlinks"
[[ "$(cat "$test_home/home-manager-locale")" == C ]] \
  || fail "Home Manager runs with English locale"
grep -Fqx '[+] Applying Home Manager configuration' "$test_home/switch-output" \
  || fail "switch prints a Docker-style heading"
grep -Fqx ' ✔ Backed up ~/.codex/skills -> ~/.codex/skills.hm-backup.1' \
  "$test_home/switch-output" || fail "switch prints concise backup status"
grep -Fqx ' ✔ Backed up ~/.claude/skills -> ~/.claude/skills.hm-backup' \
  "$test_home/switch-output" || fail "switch prints concise backup status"
grep -Fqx ' ✔ Backed up ~/.p10k.zsh -> ~/.p10k.zsh.hm-backup' \
  "$test_home/switch-output" || fail "switch summarizes Home Manager backups"
grep -Fqx ' ! Home Manager has unread news; run `home-manager news` to review it.' \
  "$test_home/switch-output" || fail "switch preserves the Home Manager news notice"
grep -Fqx ' ✔ Home Manager configuration applied' "$test_home/switch-output" \
  || fail "switch prints a concise success status"
if grep -Fq 'Verbose activation detail' "$test_home/switch-output" \
  || grep -Fq "$test_home" "$test_home/switch-output"; then
  fail "successful switch output hides verbose absolute-path logs"
fi

mkdir -p "$test_home/nix/store/current-home-manager-files/.codex/skills"
ln -s "$test_home/nix/store/current-home-manager-files/.codex/skills" \
  "$test_home/.codex/skills"
HOME="$test_home" "$test_home/switch" > "$test_home/switch-output" 2>&1
[[ -L "$test_home/.codex/skills" ]] \
  || fail "Home Manager-owned directory symlink is left in place"
[[ ! -e "$test_home/.codex/skills.hm-backup.2" ]] \
  || fail "Home Manager-owned directory symlink is not backed up again"

set +e
HOME="$test_home" HOME_MANAGER_FAIL=1 \
  "$test_home/switch" > "$test_home/failure-output" 2>&1
switch_status=$?
set -e
[[ "$switch_status" == 42 ]] || fail "switch preserves the activation failure status"
grep -Fq ' ✘ Home Manager switch failed' "$test_home/failure-output" \
  || fail "switch prints a failure status"
grep -Fq 'Home Manager activation failed' "$test_home/failure-output" \
  || fail "switch prints activation details on failure"

printf 'ok: shell scripts are kept in .sh files\n'
