set -euo pipefail
exec sudo "@DARWIN_REBUILD_BIN@" switch --flake "path:$PWD#@HOME_CONFIGURATION_NAME@" "$@"
