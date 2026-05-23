#!/usr/bin/env bash
set -euo pipefail

CONFIG="kaggle.yml"
PROFILE=""
WORKDIR="kaggle_workdir"
MODE="push-only"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --workdir)
      WORKDIR="$2"
      shift 2
      ;;
    --push-only)
      MODE="push-only"
      shift
      ;;
    --submit)
      MODE="submit"
      shift
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

RENDER_ARGS=(--config "$CONFIG" --workdir "$WORKDIR")
if [[ -n "$PROFILE" ]]; then
  RENDER_ARGS+=(--profile "$PROFILE")
fi

SUMMARY_JSON="$(python3 scripts/kaggle/render_metadata.py "${RENDER_ARGS[@]}")"

PROFILE_NAME="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["profile"])' "$SUMMARY_JSON")"
NOTEBOOK_PATH="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["notebook"])' "$SUMMARY_JSON")"
KERNEL_ID="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["kernel_id"])' "$SUMMARY_JSON")"
SUBMIT_FILE="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("submit", {}).get("file", ""))' "$SUMMARY_JSON")"
SUBMIT_COMPETITION="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("submit", {}).get("competition", ""))' "$SUMMARY_JSON")"
SUBMIT_MESSAGE="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("submit", {}).get("message", ""))' "$SUMMARY_JSON")"

echo "selected_profile=$PROFILE_NAME"
echo "notebook=$NOTEBOOK_PATH"
echo "kernel_id=$KERNEL_ID"
echo "mode=$MODE"
if [[ -n "$SUBMIT_COMPETITION" ]]; then
  echo "submit_competition=$SUBMIT_COMPETITION"
fi
if [[ -n "$SUBMIT_FILE" ]]; then
  echo "submit_file=$SUBMIT_FILE"
fi

have_cli() {
  command -v kaggle >/dev/null 2>&1
}

push_with_python_api() {
  python3 - "$WORKDIR" <<'PY'
from pathlib import Path
import sys

from kaggle.api.kaggle_api_extended import KaggleApi

workdir = Path(sys.argv[1])
api = KaggleApi()
api.authenticate()
api.kernels_push(str(workdir))
print(f"pushed_with_python_api={workdir}")
PY
}

submit_with_python_api() {
  python3 - "$1" "$2" "$3" <<'PY'
from pathlib import Path
import sys

from kaggle.api.kaggle_api_extended import KaggleApi

submission_path = Path(sys.argv[1])
competition = sys.argv[2]
message = sys.argv[3]

api = KaggleApi()
api.authenticate()
api.competition_submit(str(submission_path), message, competition)
print(f"submitted_with_python_api={submission_path}")
PY
}

echo "==> pushing kernel"
if have_cli; then
  kaggle kernels push -p "$WORKDIR"
else
  push_with_python_api
fi

if [[ "$MODE" == "push-only" ]]; then
  echo "==> done: kernel push only"
  exit 0
fi

if [[ -z "$SUBMIT_COMPETITION" || -z "$SUBMIT_FILE" ]]; then
  echo "Missing submit.competition or submit.file in kaggle.yml" >&2
  exit 1
fi

OUTPUT_DIR="kaggle_output"
SUBMISSION_PATH="$WORKDIR/$SUBMIT_FILE"

if have_cli; then
  echo "==> waiting for kernel completion"
  while true; do
    STATUS="$(kaggle kernels status "$KERNEL_ID" || true)"
    echo "$STATUS"

    if echo "$STATUS" | grep -qiE 'complete|succeeded'; then
      break
    fi
    if echo "$STATUS" | grep -qiE 'error|failed|cancel'; then
      echo "Kernel failed or was cancelled" >&2
      exit 1
    fi
    sleep 60
  done

  echo "==> downloading kernel output"
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"
  kaggle kernels output "$KERNEL_ID" -p "$OUTPUT_DIR"
  SUBMISSION_PATH="$OUTPUT_DIR/$SUBMIT_FILE"
fi

if [[ ! -f "$SUBMISSION_PATH" ]]; then
  echo "Expected submission file not found: $SUBMISSION_PATH" >&2
  echo "If Kaggle CLI is unavailable, place the file locally before running --submit." >&2
  exit 1
fi

echo "==> submitting competition file"
if have_cli; then
  kaggle competitions submit -c "$SUBMIT_COMPETITION" -f "$SUBMISSION_PATH" -m "$SUBMIT_MESSAGE"
else
  submit_with_python_api "$SUBMISSION_PATH" "$SUBMIT_COMPETITION" "$SUBMIT_MESSAGE"
fi

echo "==> done: competition submission completed"
