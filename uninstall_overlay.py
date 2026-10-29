#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else "/home/pi/sg1_v4")

def clean(relative, patterns):
    path = root / relative
    if not path.is_file():
        return
    original = path.read_text(encoding="utf-8", errors="replace")
    text = original
    for pattern in patterns:
        text = re.sub(pattern, "", text, count=1, flags=re.DOTALL | re.MULTILINE)
    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"Cleaned: {relative}")

clean("web/js/top_menu.js", [
    r"\nfunction silence_mode_bool_from_config\(.*?(?=\n\$\(function\(\) \{)",
    r"^\s*install_silence_mode_menu_button\(\);\n",
])
clean("web/main.css", [
    r"\n/\* Silence Mode menu toggle \*/.*?\.silence-mode-label\s*\{.*?\}\n",
])
clean("web/retro/js/navigation.js", [
    r'^\s*<a href="#" class="a-silence-mode[^\n]*\n',
    r"\nasync function silenceModeReadConfig\(.*?\nsetTimeout\(silenceModeRefresh, 0\);\n",
])
clean("web/retro/css/navigation.css", [
    r"\n/\* Silence Mode menu toggle \*/.*?\.a-silence-mode\.silence-mode-on \.silence-mode-dot\s*\{.*?\}\n",
])
