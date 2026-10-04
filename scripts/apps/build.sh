set -euo pipefail
exec "@HOME_MANAGER_BIN@" build --impure --flake "@FLAKE_REF@" "$@"
