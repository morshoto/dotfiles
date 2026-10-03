#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bootstrap="$repo_root/scripts/bootstrap"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -x "$bootstrap" ]] || fail "bootstrap entry point is executable"

fixture="$(mktemp -d)"
fake_bin="$(mktemp -d)"
trap 'rm -rf "$fixture" "$fake_bin"' EXIT
mkdir -p "$fixture/nix/hosts"
git -C "$fixture" init -q
touch "$fixture/flake.nix"
touch "$fixture/nix/hosts/apple-silicon.nix"
cat >"$fixture/nix/hosts/default.nix" <<'EOF'
{
  apple-silicon = import ./apple-silicon.nix;
}
EOF
cat >"$fixture/nix/local.example.nix" <<'EOF'
{
  hostName = "apple-silicon";
  username = "your-username";
  homeDirectory = "/Users/your-username";
  dotfilesDir = "/path/to/dotfiles";
}
EOF

cat >"$fake_bin/nix" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$BOOTSTRAP_TEST_LOG"
EOF
chmod +x "$fake_bin/nix"
log="$fixture/nix.log"

run_bootstrap() {
  local host_name="${1:-}"
  PATH="$fake_bin:$PATH" \
    DOTFILES_REPO_DIR="$fixture" \
    DOTFILES_HOST="$host_name" \
    DOTFILES_BOOTSTRAP_SKIP_PLATFORM_CHECK=1 \
    DOTFILES_USERNAME=tester \
    DOTFILES_HOME=/Users/tester \
    BOOTSTRAP_TEST_LOG="$log" \
    "$bootstrap"
}

run_bootstrap
[[ -f "$fixture/nix/local.nix" ]] || fail "bootstrap creates local configuration"
grep -Fq 'username = "tester"' "$fixture/nix/local.nix" || fail "bootstrap initializes username"
grep -Fq 'homeDirectory = "/Users/tester"' "$fixture/nix/local.nix" || fail "bootstrap initializes home"
grep -Fq "dotfilesDir = \"$fixture\"" "$fixture/nix/local.nix" || fail "bootstrap initializes repo path"
grep -Fq 'hostName = "apple-silicon"' "$fixture/nix/local.nix" || fail "bootstrap selects a registered host"
grep -Fq "#switch" "$log" || fail "bootstrap applies Home Manager"

cp "$fixture/nix/local.nix" "$fixture/nix/local.before.nix"
run_bootstrap
cmp -s "$fixture/nix/local.nix" "$fixture/nix/local.before.nix" \
  || fail "bootstrap preserves an existing local configuration"

rm "$fixture/nix/local.nix"
if run_bootstrap generic-darwin; then
  fail "bootstrap rejects an unregistered host"
fi
[[ ! -e "$fixture/nix/local.nix" ]] || fail "bootstrap rejects unknown hosts before writing local config"

printf 'ok: bootstrap tests\n'
