#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try normal venv first; fall back to --without-pip for sandboxed environments
# where ensurepip is blocked from spawning subprocesses.
if ! python3 -m venv "$SCRIPT_DIR/.venv" 2>/dev/null; then
  echo "Standard venv creation failed, attempting fallback..." >&2
  python3 -m venv --without-pip --system-site-packages "$SCRIPT_DIR/.venv"
  if ! "$SCRIPT_DIR/.venv/bin/python3" -m pip --version &>/dev/null; then
    echo "ERROR: pip is not available in the venv. The fallback to --system-site-packages also failed." >&2
    echo "Please ensure your system 'python3' has 'pip' installed." >&2
    exit 1
  fi
fi

"$SCRIPT_DIR/.venv/bin/python3" -m pip install -q 'google-ads>=29.0.0'
echo "Done. Test: $SCRIPT_DIR/.venv/bin/python3 $SCRIPT_DIR/query.py --help"
