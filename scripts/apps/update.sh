set -euo pipefail

lock_snapshot="$(mktemp)"
trap 'rm -f "$lock_snapshot"' EXIT
cp flake.lock "$lock_snapshot"

printf '[+] Flake input update\n'
if nix flake update --flake "path:$PWD"; then
  printf ' ✔ %-30s %s\n' 'Flake lock' 'Updated'
else
  update_status=$?
  printf ' ✘ %-30s %s\n' 'Flake lock' 'Update failed' >&2
  exit "$update_status"
fi

if lock_summary="$(
  DOTFILES_OLD_LOCK_FILE="$lock_snapshot" \
    DOTFILES_NEW_LOCK_FILE="$PWD/flake.lock" \
    nix eval --raw --impure --expr '
      let
        readLock = environmentName:
          builtins.fromJSON (
            builtins.readFile (builtins.toPath (builtins.getEnv environmentName))
          );
        oldLock = readLock "DOTFILES_OLD_LOCK_FILE";
        newLock = readLock "DOTFILES_NEW_LOCK_FILE";
        revision = lock: name:
          if !builtins.hasAttr name lock.nodes then
            "not present"
          else
            let locked = lock.nodes.${name}.locked or { };
            in
            if builtins.hasAttr "rev" locked then
              locked.rev
            else if builtins.hasAttr "narHash" locked then
              locked.narHash
            else
              "unlocked";
        inputNames = builtins.attrNames (oldLock.nodes // newLock.nodes);
        changedInputs = builtins.filter (
          name: revision oldLock name != revision newLock name
        ) inputNames;
      in
      builtins.concatStringsSep "\n" (
        map (
          name:
          builtins.concatStringsSep "\t" [
            name
            (revision oldLock name)
            (revision newLock name)
          ]
        ) changedInputs
      )
    '
)"; then
  :
else
  summary_status=$?
  printf ' ✘ %-30s %s\n' 'Flake input summary' 'Failed' >&2
  printf ' ! Review flake.lock, then run `nix run .#switch` manually\n' >&2
  exit "$summary_status"
fi

if [[ -n "$lock_summary" ]]; then
  printf '[+] Changed flake inputs\n'
  while IFS=$'\t' read -r input old_revision new_revision; do
    [[ -n "$input" ]] || continue
    printf ' ✔ %-30s %s -> %s\n' "$input" "$old_revision" "$new_revision"
  done <<< "$lock_summary"
else
  printf ' ✔ %-30s %s\n' 'Flake inputs' 'Up to date'
fi

nix run "path:$PWD#switch" -- "$@"
