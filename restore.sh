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

BACKUP_DIR="$(find "$TARGET/backups" -maxdepth 1 -type d -name 'silence-mode-*' 2>/dev/null | sort | tail -n 1)"
if [[ -z "$BACKUP_DIR" || ! -f "$BACKUP_DIR/manifest.txt" ]]; then
  echo "ERROR: no Silence Mode backup with manifest found under $TARGET/backups" >&2
  exit 1
fi

echo "Restoring from: $BACKUP_DIR"

while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  mkdir -p "$(dirname "$TARGET/$rel")"
  cp -a "$BACKUP_DIR/$rel" "$TARGET/$rel"
  echo "Restored: $rel"
done < "$BACKUP_DIR/manifest.txt"

find "$TARGET" -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true

echo "Restore complete."
echo "Restart manually when ready:"
echo "  sudo systemctl restart stargate.service"
