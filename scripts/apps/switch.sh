set -euo pipefail
exec "@HOME_MANAGER_BIN@" switch -b hm-backup --impure --flake "@FLAKE_REF@" "$@"
