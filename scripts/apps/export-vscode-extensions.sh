set -euo pipefail

manifest="$PWD/vscode/extensions.txt"
[[ -f "$manifest" && -f "$PWD/flake.nix" ]] || {
  printf 'Run this command from the dotfiles repository root.\n' >&2
  exit 1
}
command -v code >/dev/null 2>&1 || {
  printf 'VS Code command `code` is unavailable.\n' >&2
  exit 1
}

additions=()
addition_count=0
while (( $# )); do
  case "$1" in
    --add)
      (( $# >= 2 )) || { printf 'Expected an extension ID after --add.\n' >&2; exit 2; }
      additions+=("$2")
      addition_count=$((addition_count + 1))
      shift 2
      ;;
    *)
      printf 'Usage: nix run .#export-vscode-extensions -- [--add ID ...]\n' >&2
      exit 2
      ;;
  esac
done

installed_file="$(mktemp)"
next_file=""
trap 'rm -f "$installed_file"; [[ -z "$next_file" ]] || rm -f "$next_file"' EXIT
if ! code --list-extensions > "$installed_file"; then
  printf 'Could not list VS Code extensions.\n' >&2
  exit 1
fi
LC_ALL=C sort -u "$installed_file" -o "$installed_file"

if (( addition_count == 0 )); then
  printf 'Installed extensions absent from vscode/extensions.txt:\n'
  LC_ALL=C comm -23 "$installed_file" <(LC_ALL=C sort -u "$manifest")
  exit 0
fi

for extension in "${additions[@]}"; do
  if ! grep -Fxq -- "$extension" "$installed_file"; then
    printf 'Extension is not installed: %s\n' "$extension" >&2
    exit 1
  fi
done

next_file="$(mktemp "$manifest.tmp.XXXXXX")"
{
  cat "$manifest"
  printf '%s\n' "${additions[@]}"
} | LC_ALL=C sort -u > "$next_file"
if cmp -s "$manifest" "$next_file"; then
  printf 'VS Code extension manifest is unchanged.\n'
  exit 0
fi
mv "$next_file" "$manifest"
next_file=""
printf 'Updated vscode/extensions.txt. Review the diff before committing:\n'
git diff -- vscode/extensions.txt
