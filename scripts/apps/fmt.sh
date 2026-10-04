set -euo pipefail
files=()
while IFS= read -r -d "" file; do
  files+=("$file")
done < <(find . -type f -name "*.nix" -print0)

if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

exec "@NIXFMT_BIN@" "$@" "${files[@]}"
