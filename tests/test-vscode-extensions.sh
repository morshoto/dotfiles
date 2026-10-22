#!/usr/bin/env bash
set -euo pipefail

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/repo/vscode" "$test_root/bin"
touch "$test_root/repo/flake.nix" "$test_root/repo/vscode/extensions.txt"
git -C "$test_root/repo" init -q
git -C "$test_root/repo" add flake.nix vscode/extensions.txt
git -C "$test_root/repo" -c user.name=Test -c user.email=test@example.com -c commit.gpgsign=false commit -qm baseline
printf 'publisher.beta\npublisher.alpha\npublisher.beta\n' > "$test_root/installed"

cat > "$test_root/bin/code" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  --list-extensions)
    [[ "${MOCK_LIST_FAIL:-0}" == 0 ]] || exit 17
    cat "$MOCK_INSTALLED_FILE"
    ;;
  --install-extension)
    printf '%s\n' "$2" >> "$MOCK_INSTALL_LOG"
    [[ "$2" != "${MOCK_FAIL_ID:-}" ]]
    ;;
  *) exit 2 ;;
esac
MOCK
chmod +x "$test_root/bin/code"

export MOCK_INSTALLED_FILE="$test_root/installed"
export MOCK_INSTALL_LOG="$test_root/install-log"
export PATH="$test_root/bin:$PATH"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
run_export() { (cd "$test_root/repo" && bash "$source_root/scripts/apps/export-vscode-extensions.sh" "$@"); }
run_install() { (cd "$test_root/repo" && bash "$source_root/scripts/apps/install-vscode-extensions.sh" "$@"); }

run_export > "$test_root/candidates"
grep -Fxq publisher.alpha "$test_root/candidates" || fail 'export lists alpha candidate'
grep -Fxq publisher.beta "$test_root/candidates" || fail 'export lists beta candidate'
[[ ! -s "$test_root/repo/vscode/extensions.txt" ]] || fail 'candidate review is read-only'

if run_export --add publisher.alpha --add publisher.absent > "$test_root/output" 2>&1; then
  fail 'unknown installed ID is rejected'
fi
[[ ! -s "$test_root/repo/vscode/extensions.txt" ]] || fail 'invalid batch leaves manifest unchanged'

run_export --add publisher.beta --add publisher.alpha --add publisher.beta > "$test_root/output"
printf 'publisher.alpha\npublisher.beta\n' > "$test_root/expected"
cmp -s "$test_root/expected" "$test_root/repo/vscode/extensions.txt" \
  || fail 'explicit additions are sorted and unique'
run_export > "$test_root/candidates"
[[ "$(wc -l < "$test_root/candidates" | tr -d ' ')" == 1 ]] \
  || fail 'tracked IDs are absent from candidates'

printf 'publisher.alpha\n' > "$test_root/installed"
run_install > "$test_root/output"
grep -Fxq 'Already installed: publisher.alpha' "$test_root/output" \
  || fail 'restore skips installed IDs'
grep -Fxq publisher.beta "$test_root/install-log" \
  || fail 'restore installs missing ID'
[[ "$(wc -l < "$test_root/install-log" | tr -d ' ')" == 1 ]] \
  || fail 'restore does not reinstall present ID'

if MOCK_FAIL_ID=publisher.beta run_install > "$test_root/output" 2>&1; then
  fail 'restore reports installation failure'
fi
grep -Fq 'Failed to install: publisher.beta' "$test_root/output" \
  || fail 'restore names failed ID'

if MOCK_LIST_FAIL=1 run_export --add publisher.alpha > "$test_root/output" 2>&1; then
  fail 'export rejects failed VS Code listing'
fi
cmp -s "$test_root/expected" "$test_root/repo/vscode/extensions.txt" \
  || fail 'failed listing leaves manifest unchanged'
if MOCK_LIST_FAIL=1 run_install > "$test_root/output" 2>&1; then
  fail 'restore rejects failed VS Code listing'
fi
if PATH=/usr/bin:/bin run_export > "$test_root/output" 2>&1; then
  fail 'export requires VS Code CLI'
fi
if PATH=/usr/bin:/bin run_install > "$test_root/output" 2>&1; then
  fail 'restore requires VS Code CLI'
fi

printf 'ok: VS Code extension sync tests\n'
