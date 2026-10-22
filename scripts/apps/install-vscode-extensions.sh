set -euo pipefail

manifest="$PWD/vscode/extensions.txt"
[[ -f "$manifest" && -f "$PWD/flake.nix" ]] || {
  printf 'Run this command from the dotfiles repository root.\n' >&2
  exit 1
}
(( $# == 0 )) || {
  printf 'Usage: nix run .#install-vscode-extensions\n' >&2
  exit 2
}
command -v code >/dev/null 2>&1 || {
  printf 'VS Code command `code` is unavailable.\n' >&2
  exit 1
}

installed_file="$(mktemp)"
trap 'rm -f "$installed_file"' EXIT
if ! code --list-extensions > "$installed_file"; then
  printf 'Could not list VS Code extensions.\n' >&2
  exit 1
fi

failed=0
while IFS= read -r extension || [[ -n "$extension" ]]; do
  [[ -n "$extension" ]] || continue
  if grep -Fxiq -- "$extension" "$installed_file"; then
    printf 'Already installed: %s\n' "$extension"
  elif code --install-extension "$extension"; then
    printf 'Installed: %s\n' "$extension"
  else
    printf 'Failed to install: %s\n' "$extension" >&2
    failed=1
  fi
done < "$manifest"
exit "$failed"
