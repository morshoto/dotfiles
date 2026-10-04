set -euo pipefail
export HOME="$TMPDIR/home"
mkdir -p "$HOME"

for test_script in \
  "$src/tests/test-bootstrap.sh" \
  "$src/tests/test-documentation.sh" \
  "$src/tests/test-host-configurations.sh" \
  "$src/tests/test-darwin-configuration.sh" \
  "$src/tests/test-update-flake-workflow.sh" \
  "$src/tests/test-update-app.sh" \
  "$src/tests/test-flake-checks.sh" \
  "$src/tests/test-shared-ai.sh" \
  "$src/tests/test-codex-config.sh" \
  "$src/tests/test-zsh-config.sh" \
  "$src/tests/test-nix-shell-scripts.sh" \
  "$src/tests/test-help-app.sh"; do
  bash "$test_script"
done

touch "$out"
