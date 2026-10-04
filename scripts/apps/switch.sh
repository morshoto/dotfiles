set -euo pipefail

backup_directory_symlink() {
  local target_path="$1"
  local link_target backup_path suffix

  if [[ ! -L "$target_path" || ! -d "$target_path" ]]; then
    return
  fi

  link_target="$(readlink "$target_path")"
  case "$link_target" in
    @NIX_STORE_DIR@/*-home-manager-files/*)
      return
      ;;
  esac

  backup_path="$target_path.hm-backup"
  suffix=1
  while [[ -e "$backup_path" || -L "$backup_path" ]]; do
    backup_path="$target_path.hm-backup.$suffix"
    suffix=$((suffix + 1))
  done

  mv "$target_path" "$backup_path"
  printf 'Preserving directory symlink %s at %s\n' "$target_path" "$backup_path" >&2
}

backup_directory_symlink "$HOME/.codex/skills"
backup_directory_symlink "$HOME/.claude/skills"

exec "@HOME_MANAGER_BIN@" switch -b hm-backup --impure --flake "@FLAKE_REF@" "$@"
