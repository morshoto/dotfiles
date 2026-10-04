set -euo pipefail
nix flake update --flake "path:$PWD"
exec nix run "path:$PWD#switch" -- "$@"
