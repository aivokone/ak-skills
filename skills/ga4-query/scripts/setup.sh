#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try normal venv first; fall back to --without-pip for sandboxed environments
# where ensurepip is blocked from spawning subprocesses.
if ! python3 -m venv "$SCRIPT_DIR/.venv" 2>/dev/null; then
  python3 -m venv --without-pip --system-site-packages "$SCRIPT_DIR/.venv"
fi

"$SCRIPT_DIR/.venv/bin/python3" -m pip install -q \
  'google-analytics-data>=0.18.0' \
  'google-analytics-admin>=0.22.0' \
  'google-auth>=2.0.0' \
  'pyyaml>=6.0'
echo "Done. Test: $SCRIPT_DIR/.venv/bin/python3 $SCRIPT_DIR/query.py --help"
