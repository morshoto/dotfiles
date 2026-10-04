set -euo pipefail
export LC_ALL=C

success_mark='✔'
failure_mark='✘'
if [[ -t 1 ]]; then
  success_mark=$'\033[32m✔\033[0m'
  failure_mark=$'\033[31m✘\033[0m'
fi

backup_directory_symlink() {
  local relative_path="$1"
  local target_path="$HOME/$relative_path"
  local target_label="~/$relative_path"
  local link_target backup_path backup_label suffix

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
  backup_label="$target_label.hm-backup"
  suffix=1
  while [[ -e "$backup_path" || -L "$backup_path" ]]; do
    backup_path="$target_path.hm-backup.$suffix"
    backup_label="$target_label.hm-backup.$suffix"
    suffix=$((suffix + 1))
  done

  if ! mv "$target_path" "$backup_path"; then
    printf ' %s Failed to back up %s\n' "$failure_mark" "$target_label" >&2
    return 1
  fi
  printf ' %s Backed up %s -> %s\n' "$success_mark" "$target_label" "$backup_label"
}

report_home_manager_backups() {
  local target_path backup_path target_label backup_label

  while IFS='|' read -r target_path backup_path; do
    [[ -n "$target_path" && -n "$backup_path" ]] || continue
    target_label="$target_path"
    backup_label="$backup_path"
    if [[ "$target_path" == "$HOME/"* ]]; then
      target_label="~/${target_path#"$HOME"/}"
    fi
    if [[ "$backup_path" == "$HOME/"* ]]; then
      backup_label="~/${backup_path#"$HOME"/}"
    fi
    printf ' %s Backed up %s -> %s\n' "$success_mark" "$target_label" "$backup_label"
  done < <(awk -F "'" '/will be moved to/ { print $2 "|" $6 }' "$activation_log")
}

activation_log="$(mktemp)"
trap 'rm -f "$activation_log"' EXIT

printf '[+] Applying Home Manager configuration\n'
backup_directory_symlink ".codex/skills"
backup_directory_symlink ".claude/skills"

if "@HOME_MANAGER_BIN@" switch -b hm-backup --impure --flake "@FLAKE_REF@" "$@" \
  > "$activation_log" 2>&1; then
  report_home_manager_backups
  if grep -Fq 'home-manager news' "$activation_log"; then
    printf ' ! Home Manager has unread news; run `home-manager news` to review it.\n'
  fi
  printf ' %s Home Manager configuration applied\n' "$success_mark"
else
  activation_status=$?
  printf ' %s Home Manager switch failed\n' "$failure_mark" >&2
  cat "$activation_log" >&2
  exit "$activation_status"
fi
