#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-/home/pi/sg1_v4}"
CONFIG="$TARGET/config/milkyway-config.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: config not found: $CONFIG" >&2
  exit 1
fi

python3 - "$CONFIG" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
for key in ("audio_enable", "chevron_motors_enable", "stepper_motor_enable"):
    data.setdefault(key, {})["value"] = False
path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
PY

sudo systemctl restart stargate.service
echo "Silence Mode ON"
