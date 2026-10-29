#!/usr/bin/env bash
set -euo pipefail

TARGET="/home/pi/sg1_v4"
if [[ "${1:-}" == "--target" ]]; then
  TARGET="${2:-}"
fi

if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "ERROR: target folder not found: $TARGET" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/uninstall_overlay.py" "$TARGET"

find "$TARGET" -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true

echo "Silence Mode removed surgically."
echo "Restart manually when ready:"
echo "  sudo systemctl restart stargate.service"
