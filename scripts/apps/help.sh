set -euo pipefail

printf '[+] Nix flake commands\n\n'
printf 'Usage:\n  nix run .#<command>\n\n'
printf 'Commands:\n'
cat <<'COMMANDS'
@APP_COMMANDS@
COMMANDS
printf '\nReference: doc/nix-flake-commands.md\n'
