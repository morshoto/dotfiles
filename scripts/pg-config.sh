set -euo pipefail

INCLUDEDIR="@INCLUDEDIR@"
INCLUDEDIR_SERVER="@INCLUDEDIR_SERVER@"
LIBDIR="@LIBDIR@"
BINDIR="@BINDIR@"
VERSION="@VERSION@"

case "${1:-}" in
  --version) echo "$VERSION" ;;
  --includedir) echo "$INCLUDEDIR" ;;
  --includedir-server) echo "$INCLUDEDIR_SERVER" ;;
  --libdir) echo "$LIBDIR" ;;
  --bindir) echo "$BINDIR" ;;
  --cppflags|--cflags) echo "-I$INCLUDEDIR -I$INCLUDEDIR_SERVER" ;;
  --ldflags) echo "-L$LIBDIR" ;;
  --libs) echo "-L$LIBDIR -lpq" ;;
  *)
    echo "pg_config shim (fixed Nix paths). Supported:" >&2
    echo "  --version --includedir --includedir-server --libdir --bindir --cppflags --cflags --ldflags --libs" >&2
    exit 2
    ;;
esac
