#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 -m venv "$SCRIPT_DIR/.venv"
"$SCRIPT_DIR/.venv/bin/pip" install -q \
  'google-analytics-data>=0.18.0' \
  'google-analytics-admin>=0.22.0' \
  'google-auth>=2.0.0' \
  'pyyaml>=6.0'
echo "Done. Test: $SCRIPT_DIR/.venv/bin/python3 $SCRIPT_DIR/query.py --help"
