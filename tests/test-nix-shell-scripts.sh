#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_switch_status() {
  local expected
  printf -v expected ' ✔ %-30s %s' "$1" "$2"
  grep -Fqx "$expected" "$test_home/switch-output" \
    || fail "switch prints status: $1"
}

assert_switch_progress() {
  local expected
  printf -v expected ' › %-30s %s' "$1" "$2"
  grep -Fqx "$expected" "$test_home/switch-output" \
    || fail "switch prints progress: $1"
}

for file in \
  scripts/apps/build.sh \
  scripts/apps/check.sh \
  scripts/apps/darwin-switch.sh \
  scripts/apps/fmt.sh \
  scripts/apps/help.sh \
  scripts/apps/switch.sh \
  scripts/apps/update.sh \
  scripts/install-agent-browser.sh \
  scripts/nix-format-check.sh \
  scripts/pg-config.sh \
  scripts/repository-tests.sh \
  scripts/shell-syntax-check.sh; do
  [[ -f "$repo_root/$file" ]] || fail "shell implementation lives in $file"
done

for script in build check darwin-switch fmt help switch update; do
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
if [[ "${HOME_MANAGER_WAIT_FOR_RELEASE:-0}" == 1 ]]; then
  printf 'Activating checkFilesChanged\n'
  : > "$HOME/phase-started"
  while [[ ! -e "$HOME/release-switch" ]]; do
    sleep 0.05
  done
  exit 0
fi
printf 'Activating checkFilesChanged\n'
printf 'Activating checkLinkTargets\n'
printf 'Activating writeBoundary\n'
printf 'Activating installPackages\n'
printf "replacing old 'home-manager-path'\n"
printf "installing 'home-manager-path'\n"
printf 'Activating linkGeneration\n'
printf "Cleaning up orphan links from '%s'\n" "$HOME"
printf "Creating home file links in '%s'\n" "$HOME"
printf 'Activating onFilesChange\n'
printf 'Activating setupLaunchAgents\n'
printf 'Additional activation detail\n'
printf 'Custom hook completed in %s\n' "$HOME"
printf "Existing file '%s/.p10k.zsh' is in the way of '/nix/store/example/.p10k.zsh', will be moved to '%s/.p10k.zsh.hm-backup'\n" \
  "$HOME" "$HOME"
if [[ "${HOME_MANAGER_NEWS_COUNT:-293}" == unavailable ]]; then
  printf 'Home Manager has unread news. Use "home-manager news" to review them.\n'
else
  printf 'There are %s unread news items. Use "home-manager news" to review them.\n' \
    "${HOME_MANAGER_NEWS_COUNT:-293}"
fi
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
grep -Fqx '[+] Home Manager switch' "$test_home/switch-output" \
  || fail "switch prints a Docker-style heading"
assert_switch_status '~/.codex/skills' 'Backed up to ~/.codex/skills.hm-backup.1'
assert_switch_status '~/.claude/skills' 'Backed up to ~/.claude/skills.hm-backup'
assert_switch_progress '~/.p10k.zsh' 'Backing up to ~/.p10k.zsh.hm-backup'
assert_switch_progress 'Check managed files' 'Starting'
assert_switch_progress 'Check link targets' 'Starting'
assert_switch_progress 'Create write boundary' 'Starting'
assert_switch_progress 'Install packages' 'Starting'
assert_switch_progress 'Home Manager package' 'Replacing home-manager-path'
assert_switch_progress 'Home Manager package' 'Installing home-manager-path'
assert_switch_progress 'Link generation' 'Starting'
assert_switch_progress 'Home files' 'Removing stale links'
assert_switch_progress 'Home files' 'Linking'
assert_switch_progress 'Run file change hooks' 'Starting'
assert_switch_progress 'Set up launch agents' 'Starting'
grep -Fqx '   Additional activation detail' "$test_home/switch-output" \
  || fail "switch preserves additional activation details"
grep -Fqx '   Custom hook completed in ~' "$test_home/switch-output" || {
  cat "$test_home/switch-output" >&2
  fail "switch shortens home paths in additional details"
}
grep -Fqx ' ! Home Manager has 293 unread news items; run `home-manager news` to review it.' \
  "$test_home/switch-output" || fail "switch prints the Home Manager unread news count"
assert_switch_status 'Home Manager configuration' 'Applied'
if grep -Fq "$test_home" "$test_home/switch-output"; then
  fail "successful switch output hides absolute paths"
fi

HOME="$test_home" HOME_MANAGER_NEWS_COUNT=unavailable \
  "$test_home/switch" > "$test_home/news-output" 2>&1
grep -Fqx ' ! Home Manager has unread news; run `home-manager news` to review it.' \
  "$test_home/news-output" || fail "switch falls back when the news count is unavailable"

HOME="$test_home" HOME_MANAGER_WAIT_FOR_RELEASE=1 \
  "$test_home/switch" > "$test_home/stream-output" 2>&1 &
stream_pid=$!
attempt=0
while [[ ! -f "$test_home/phase-started" && "$attempt" -lt 100 ]]; do
  sleep 0.05
  attempt=$((attempt + 1))
done

stream_line=''
printf -v stream_line ' › %-30s %s' 'Check managed files' 'Starting'
attempt=0
while [[ -f "$test_home/phase-started" && "$attempt" -lt 100 ]] \
  && ! grep -Fqx "$stream_line" "$test_home/stream-output"; do
  sleep 0.05
  attempt=$((attempt + 1))
done
stream_progress_visible=0
if grep -Fqx "$stream_line" "$test_home/stream-output"; then
  stream_progress_visible=1
fi
touch "$test_home/release-switch"
set +e
wait "$stream_pid"
stream_status=$?
set -e
[[ -f "$test_home/phase-started" ]] || fail "switch starts the mocked activation"
[[ "$stream_status" == 0 ]] || fail "streamed switch completes successfully"
[[ "$stream_progress_visible" == 1 ]] \
  || fail "switch streams activation progress before completion"

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
grep -Fq ' ✘ Home Manager configuration     Failed' "$test_home/failure-output" \
  || fail "switch prints a failure status"
grep -Fq 'Home Manager activation failed' "$test_home/failure-output" \
  || fail "switch prints activation details on failure"

printf 'ok: shell scripts are kept in .sh files\n'
