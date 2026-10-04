#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
zsh_dir="$repo_root/zsh"
shell_config="$repo_root/nix/home/shell.nix"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

for file in environment aliases keybindings completion integrations home-manager; do
  [[ -f "$zsh_dir/$file.zsh" ]] || fail "zsh config includes $file.zsh"
done

[[ -f "$zsh_dir/init.zsh" ]] || fail "zsh config includes init.zsh"

previous_line=0
for file in environment aliases keybindings completion integrations extra local home-manager; do
  line="$(grep -nF "source \"\$HOME/.config/zsh/$file.zsh\"" "$zsh_dir/init.zsh" | cut -d: -f1 | head -n1 || true)"
  [[ -n "$line" ]] || fail "Zsh init sources $file.zsh"
  (( line > previous_line )) || fail "Zsh init sources $file.zsh in order"
  previous_line="$line"
done

grep -Fq 'initContent = builtins.readFile ../../zsh/init.zsh;' "$shell_config" \
  || fail "Home Manager reads init content from a Zsh file"
grep -Fq 'programs.zsh = {' "$shell_config" \
  || fail "Home Manager configures Zsh"
grep -Fq '    enable = true;' "$shell_config" \
  || fail "Home Manager enables Zsh"
grep -Fq 'programs.fzf.enable' "$shell_config" \
  || fail "Home Manager enables fzf"
grep -Fq 'programs.zoxide.enable' "$shell_config" \
  || fail "Home Manager enables zoxide"

if grep -Eq 'shellAliases|case_insensitive_|matcher-list|powerlevel10k|home-manager\(\)' "$shell_config"; then
  fail "interactive behavior lives in zsh files"
fi

grep -Fqx 'zsh/local.zsh' "$repo_root/.gitignore" \
  || fail "host-only zsh config is ignored"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
mock_bin="$test_home/bin"
mkdir -p "$mock_bin" "$test_home/.config" \
  "$test_home/Downloads/google-cloud-sdk"
cp -R "$zsh_dir" "$test_home/.config/zsh"
chmod -R u+w "$test_home/.config/zsh"
cat >"$mock_bin/home-manager" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*"
MOCK
chmod +x "$mock_bin/home-manager"
cat >"$test_home/Downloads/google-cloud-sdk/path.zsh.inc" <<'MOCK'
export TEST_GOOGLE_CLOUD_PATH=loaded
MOCK
cat >"$test_home/Downloads/google-cloud-sdk/completion.zsh.inc" <<'MOCK'
export TEST_GOOGLE_CLOUD_COMPLETION=loaded
MOCK
cat >"$test_home/.config/zsh/local.zsh" <<'MOCK'
export TEST_HOST_LOCAL_INTEGRATION=loaded
MOCK

cat >"$test_home/test-config.zsh" <<'ZSH'
setopt errexit nounset pipefail

source "$HOME/.config/zsh/init.zsh"

[[ "$EDITOR" == 'code --wait' ]]
[[ "$LANG" == 'ja_JP.UTF-8' ]]
for alias_name in ll gs gc gp python python3 k tf; do
  alias "$alias_name" >/dev/null
done
[[ "$(bindkey '^[[A')" == *case_insensitive_up_line_or_beginning_search* ]]
[[ "$(bindkey '^[[B')" == *case_insensitive_down_line_or_beginning_search* ]]
[[ "$(bindkey '^[OA')" == *case_insensitive_up_line_or_beginning_search* ]]
[[ "$(bindkey '^[OB')" == *case_insensitive_down_line_or_beginning_search* ]]
[[ "$(zstyle -L ':completion:*' matcher-list)" == *'m:{a-z}={A-Z}'* ]]
[[ "$FZF_DEFAULT_OPTS" == *--case-insensitive* ]]
[[ "$FZF_DEFAULT_OPTS" == *--height=40%* ]]
[[ "$PNPM_HOME" == "$HOME/Library/pnpm" ]]
[[ "$TEST_GOOGLE_CLOUD_PATH" == loaded ]]
[[ "$TEST_GOOGLE_CLOUD_COMPLETION" == loaded ]]
[[ "$TEST_HOST_LOCAL_INTEGRATION" == loaded ]]

[[ -z "${TEST_POWERLEVEL10K_THEME:-}" ]]
[[ -z "${TEST_POWERLEVEL10K_CONFIG:-}" ]]
mkdir -p "$HOME/powerlevel10k"
print 'export TEST_POWERLEVEL10K_THEME=loaded' > "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
print 'export TEST_POWERLEVEL10K_CONFIG=loaded' > "$HOME/.p10k.zsh"
source "$ZSH_CONFIG_DIR/integrations.zsh"
[[ "$TEST_POWERLEVEL10K_THEME" == loaded ]]
[[ "$TEST_POWERLEVEL10K_CONFIG" == loaded ]]

[[ "$(home-manager switch)" == 'switch -b hm-backup' ]]
[[ "$(home-manager switch -b custom)" == 'switch -b custom' ]]
[[ "$(home-manager status)" == status ]]
ZSH

if ZSH_CONFIG_DIR="$zsh_dir" \
  HOME="$test_home" \
  FZF_DEFAULT_OPTS='--height=40%' \
  PATH="$mock_bin:/usr/bin:/bin" \
  zsh -f -i "$test_home/test-config.zsh"; then
  :
else
  fail "interactive zsh behavior works"
fi

for file in init.zsh aliases.zsh environment.zsh keybindings.zsh completion.zsh integrations.zsh extra.zsh home-manager.zsh local.zsh; do
  grep -Fq "$file" "$repo_root/zsh/README.md" \
    || fail "zsh README documents $file"
done
grep -Fq '.p10k.zsh' "$repo_root/zsh/README.md" \
  || fail "zsh README documents host-owned Powerlevel10k settings"
grep -Fq 'home-manager switch' "$repo_root/zsh/README.md" \
  || fail "zsh README explains when edits take effect"

printf 'ok: zsh config tests\n'
