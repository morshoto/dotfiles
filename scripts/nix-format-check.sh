set -euo pipefail

while IFS= read -r -d "" file; do
  nixfmt --check "$file"
done < <(find "$src" -type f -name '*.nix' -print0)

touch "$out"
