#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 -m venv "$SCRIPT_DIR/.venv"
"$SCRIPT_DIR/.venv/bin/pip" install -q 'google-ads>=29.0.0'
echo "Done. Test: $SCRIPT_DIR/.venv/bin/python3 $SCRIPT_DIR/query.py --help"
