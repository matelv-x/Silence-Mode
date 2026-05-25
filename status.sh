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

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
vals = {key: bool(data.get(key, {}).get("value")) for key in ("audio_enable", "chevron_motors_enable", "stepper_motor_enable")}
silence = not any(vals.values())
print("Silence Mode:", "ON" if silence else "OFF")
for key, value in vals.items():
    print(f"{key}: {value}")
PY
