home-manager() {
  if [[ "${1:-}" == switch ]]; then
    for arg in "$@"; do
      if [[ "$arg" == -b || "$arg" == --backup-file-extension || "$arg" == --backup ]]; then
        command home-manager "$@"
        return
      fi
    done

    shift
    command home-manager switch -b hm-backup "$@"
    return
  fi

  command home-manager "$@"
}
