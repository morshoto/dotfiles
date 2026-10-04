set -euo pipefail

while IFS= read -r -d "" file; do
  bash -n "$file"
done < <(find "$src/scripts" "$src/tests" -type f -name '*.sh' -print0)

while IFS= read -r -d "" file; do
  zsh -n "$file"
done < <(find "$src/zsh" -type f -name '*.zsh' -print0)

while IFS= read -r -d "" file; do
  fish -n "$file"
done < <(find "$src/fish" -type f -name '*.fish' -print0)

touch "$out"
