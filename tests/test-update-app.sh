#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
real_nix="$(command -v nix)"
test_root="$(mktemp -d)"
mock_bin="$test_root/bin"
test_repo="$test_root/repo"
mock_log="$test_root/nix-calls"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$mock_bin" "$test_repo"
cat > "$test_root/old-lock.json" <<'LOCK'
{"nodes":{"nixpkgs":{"locked":{"rev":"old-revision","narHash":"old-hash"}},"root":{"inputs":{"nixpkgs":"nixpkgs"}}},"root":"root","version":7}
LOCK
cat > "$test_root/new-lock.json" <<'LOCK'
{"nodes":{"nixpkgs":{"locked":{"rev":"new-revision","narHash":"new-hash"}},"root":{"inputs":{"nixpkgs":"nixpkgs"}}},"root":"root","version":7}
LOCK
cp "$test_root/old-lock.json" "$test_repo/flake.lock"

cat > "$mock_bin/nix" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  flake)
    printf 'flake %s\n' "$2" >> "$MOCK_NIX_LOG"
    if [[ "${MOCK_UPDATE_STATUS:-0}" != 0 ]]; then
      exit "$MOCK_UPDATE_STATUS"
    fi
    cp "$FAKE_UPDATED_LOCK" "$PWD/flake.lock"
    ;;
  eval)
    printf 'eval\n' >> "$MOCK_NIX_LOG"
    if [[ "${MOCK_SUMMARY_STATUS:-0}" != 0 ]]; then
      exit "$MOCK_SUMMARY_STATUS"
    fi
    exec "$REAL_NIX" "$@"
    ;;
  run)
    printf 'run %s\n' "$2" >> "$MOCK_NIX_LOG"
    printf '[+] Home Manager switch\n'
    if [[ "${MOCK_SWITCH_STATUS:-0}" != 0 ]]; then
      printf ' ✘ Home Manager configuration     Failed\n'
      exit "$MOCK_SWITCH_STATUS"
    fi
    printf ' ✔ Home Manager configuration     Applied\n'
    ;;
  *)
    exit 2
    ;;
esac
MOCK
chmod +x "$mock_bin/nix"

run_update() {
  (cd "$test_repo" && PATH="$mock_bin:$PATH" \
    MOCK_NIX_LOG="$mock_log" REAL_NIX="$real_nix" \
    FAKE_UPDATED_LOCK="$FAKE_UPDATED_LOCK" \
    MOCK_UPDATE_STATUS="${MOCK_UPDATE_STATUS:-0}" \
    MOCK_SUMMARY_STATUS="${MOCK_SUMMARY_STATUS:-0}" \
    MOCK_SWITCH_STATUS="${MOCK_SWITCH_STATUS:-0}" \
    bash "$repo_root/scripts/apps/update.sh")
}

export FAKE_UPDATED_LOCK="$test_root/new-lock.json"
run_update > "$test_root/changed-output" 2>&1 \
  || {
    cat "$test_root/changed-output" >&2
    fail "update command succeeds when inputs and switch succeed"
  }
grep -Fq 'nixpkgs' "$test_root/changed-output" \
  || fail "update output names the changed input"
grep -Fq 'old-revision -> new-revision' "$test_root/changed-output" \
  || fail "update output shows old and new revisions"
grep -Fq '[+] Home Manager switch' "$test_root/changed-output" \
  || fail "update output identifies the switch stage"
[[ "$(wc -l < "$mock_log" | tr -d ' ')" == 3 ]] \
  || fail "update, summary, and switch run in order"
[[ "$(sed -n '1p' "$mock_log")" == 'flake update' ]] \
  || fail "flake update runs first"
[[ "$(sed -n '2p' "$mock_log")" == 'eval' ]] \
  || fail "lockfile summary runs after update"
[[ "$(sed -n '3p' "$mock_log")" == 'run path:'*'#switch' ]] \
  || fail "switch runs after the lockfile summary"

cp "$test_root/old-lock.json" "$test_repo/flake.lock"
cp "$test_root/old-lock.json" "$test_root/unchanged-lock.json"
: > "$mock_log"
FAKE_UPDATED_LOCK="$test_root/unchanged-lock.json" run_update \
  > "$test_root/unchanged-output" 2>&1 \
  || fail "update command succeeds when no inputs change"
grep -Fq '✔ Flake inputs' "$test_root/unchanged-output" \
  || fail "update output reports unchanged inputs"
grep -Fq '[+] Home Manager switch' "$test_root/unchanged-output" \
  || fail "unchanged inputs still continue to the switch"

cp "$test_root/old-lock.json" "$test_repo/flake.lock"
: > "$mock_log"
set +e
MOCK_UPDATE_STATUS=23 run_update > "$test_root/update-failure-output" 2>&1
update_status=$?
set -e
[[ "$update_status" == 23 ]] || fail "update failure status is preserved"
grep -Fq 'Flake lock' "$test_root/update-failure-output" \
  || fail "update failure is identified"
[[ "$(wc -l < "$mock_log" | tr -d ' ')" == 1 ]] \
  || fail "failed update does not summarize or switch"

cp "$test_root/old-lock.json" "$test_repo/flake.lock"
: > "$mock_log"
set +e
MOCK_SUMMARY_STATUS=17 run_update > "$test_root/summary-failure-output" 2>&1
summary_status=$?
set -e
[[ "$summary_status" == 17 ]] || fail "summary failure status is preserved"
grep -Fq 'Flake input summary' "$test_root/summary-failure-output" \
  || fail "summary failure is identified"
grep -Fq 'run `nix run .#switch` manually' "$test_root/summary-failure-output" \
  || fail "summary failure explains how to apply manually"
[[ "$(wc -l < "$mock_log" | tr -d ' ')" == 2 ]] \
  || fail "failed summary does not switch"

cp "$test_root/old-lock.json" "$test_repo/flake.lock"
: > "$mock_log"
set +e
MOCK_SWITCH_STATUS=19 run_update > "$test_root/switch-failure-output" 2>&1
switch_status=$?
set -e
[[ "$switch_status" == 19 ]] || fail "switch failure status is preserved"
grep -Fq 'Home Manager configuration     Failed' "$test_root/switch-failure-output" \
  || fail "switch failure remains distinct from update success"

printf 'ok: update app tests\n'
