set -euo pipefail
exec nix flake check "$@" "path:$PWD"
