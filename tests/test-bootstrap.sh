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
mkdir -p "$fixture/nix"
git -C "$fixture" init -q
touch "$fixture/flake.nix"
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
  PATH="$fake_bin:$PATH" \
    DOTFILES_REPO_DIR="$fixture" \
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
grep -Fq "#switch" "$log" || fail "bootstrap applies Home Manager"

cp "$fixture/nix/local.nix" "$fixture/nix/local.before.nix"
run_bootstrap
cmp -s "$fixture/nix/local.nix" "$fixture/nix/local.before.nix" \
  || fail "bootstrap preserves an existing local configuration"

printf 'ok: bootstrap tests\n'
