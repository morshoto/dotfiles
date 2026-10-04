set -euo pipefail
export LC_ALL=C

success_mark='✔'
failure_mark='✘'
progress_mark='›'
if [[ -t 1 ]]; then
  success_mark=$'\033[32m✔\033[0m'
  failure_mark=$'\033[31m✘\033[0m'
  progress_mark=$'\033[36m›\033[0m'
fi

print_status() {
  printf ' %s %-30s %s\n' "$success_mark" "$1" "$2"
}

print_progress() {
  printf ' %s %-30s %s\n' "$progress_mark" "$1" "$2"
}

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
    printf ' %s %-30s %s\n' "$failure_mark" "$target_label" 'Backup failed' >&2
    return 1
  fi
  print_status "$target_label" "Backed up to $backup_label"
}

activation_phase_label() {
  case "$1" in
    checkFilesChanged) printf 'Check managed files' ;;
    checkLinkTargets) printf 'Check link targets' ;;
    writeBoundary) printf 'Create write boundary' ;;
    installPackages) printf 'Install packages' ;;
    linkGeneration) printf 'Link generation' ;;
    onFilesChange) printf 'Run file change hooks' ;;
    setupLaunchAgents) printf 'Set up launch agents' ;;
    *) printf '%s' "$1" ;;
  esac
}

render_activation_log() {
  local line phase package target_path backup_path target_label backup_label escaped_home
  escaped_home="$(printf '%s\n' "$HOME" | sed 's/[][\\.^$*|]/\\&/g')"

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      'Activating '*)
        phase="${line#Activating }"
        print_progress "$(activation_phase_label "$phase")" 'Starting'
        ;;
      'replacing old '*)
        package="$(awk -F "'" '{ print $2 }' <<< "$line")"
        print_progress 'Home Manager package' "Replacing $package"
        ;;
      'installing '*)
        package="$(awk -F "'" '{ print $2 }' <<< "$line")"
        print_progress 'Home Manager package' "Installing $package"
        ;;
      *'will be moved to '*)
        target_path="$(awk -F "'" '{ print $2 }' <<< "$line")"
        backup_path="$(awk -F "'" '{ print $6 }' <<< "$line")"
        target_label="$target_path"
        backup_label="$backup_path"
        if [[ "$target_path" == "$HOME/"* ]]; then
          target_label="~/${target_path#"$HOME"/}"
        fi
        if [[ "$backup_path" == "$HOME/"* ]]; then
          backup_label="~/${backup_path#"$HOME"/}"
        fi
        print_progress "$target_label" "Backing up to $backup_label"
        ;;
      'Cleaning up orphan links from '*)
        print_progress 'Home files' 'Removing stale links'
        ;;
      'Creating home file links in '*)
        print_progress 'Home files' 'Linking'
        ;;
      *'unread news items.'*|*'home-manager news'*|'')
        ;;
      *)
        line="$(printf '%s\n' "$line" | sed "s|$escaped_home|~|g")"
        printf '   %s\n' "$line"
        ;;
    esac
  done
}

activation_log="$(mktemp)"
activation_stream="${activation_log}.fifo"
mkfifo "$activation_stream"
trap 'rm -f "$activation_log" "$activation_stream"' EXIT

printf '[+] Home Manager switch\n'
backup_directory_symlink ".codex/skills"
backup_directory_symlink ".claude/skills"

tee "$activation_log" < "$activation_stream" | render_activation_log &
activation_stream_pid=$!

if "@HOME_MANAGER_BIN@" switch -b hm-backup --impure --flake "@FLAKE_REF@" "$@" \
  > "$activation_stream" 2>&1; then
  activation_status=0
else
  activation_status=$?
fi

if wait "$activation_stream_pid"; then
  activation_stream_status=0
else
  activation_stream_status=$?
fi

if [[ "$activation_status" == 0 ]]; then
  if grep -Fq 'home-manager news' "$activation_log"; then
    news_item_count="$(sed -nE 's/.*There are ([0-9]+) unread news items\..*/\1/p' "$activation_log" | tail -n1)"
    if [[ -n "$news_item_count" ]]; then
      printf ' ! Home Manager has %s unread news items; run `home-manager news` to review it.\n' \
        "$news_item_count"
    else
      printf ' ! Home Manager has unread news; run `home-manager news` to review it.\n'
    fi
  fi
  print_status 'Home Manager configuration' 'Applied'
else
  printf ' %s %-30s %s\n' "$failure_mark" 'Home Manager configuration' 'Failed' >&2
  cat "$activation_log" >&2
  exit "$activation_status"
fi

if [[ "$activation_stream_status" != 0 ]]; then
  printf ' ! Unable to render all Home Manager activation details\n' >&2
  cat "$activation_log" >&2
fi
