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

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$TARGET/backups/silence-mode-$STAMP"
MANIFEST="$BACKUP_DIR/manifest.txt"

mkdir -p "$BACKUP_DIR"
: > "$MANIFEST"

python3 - "$TARGET" "$BACKUP_DIR" "$MANIFEST" <<'PY'
from pathlib import Path
import shutil
import sys

target = Path(sys.argv[1])
backup_dir = Path(sys.argv[2])
manifest = Path(sys.argv[3])


def backup(rel: str) -> bool:
    src = target / rel
    if not src.exists():
        return False
    dst = backup_dir / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    with manifest.open("a", encoding="utf-8") as fh:
        fh.write(rel + "\n")
    return True


def write_text(rel: str, text: str) -> None:
    path = target / rel
    path.write_text(text, encoding="utf-8")
    print(f"Patched: {rel}")


def append_silence_block(text: str, block: str, start_marker: str) -> str:
    start = text.find(start_marker)
    if start >= 0:
        text = text[:start].rstrip() + "\n"
    return text.rstrip() + "\n\n" + block.strip() + "\n"


classic_js_block = r"""
function silence_mode_bool_from_config(configData) {
    function flag(name) {
        return configData && configData[name] && configData[name].value === true;
    }

    return !(flag('audio_enable') || flag('chevron_motors_enable') || flag('stepper_motor_enable'));
}

function silence_mode_update_button(isOn) {
    var button = $('#silenceModeMenuButton');
    if (!button.length) {
        return;
    }

    button.toggleClass('silence-mode-on', isOn);
    button.toggleClass('silence-mode-off', !isOn);
    button.attr('title', isOn ? 'Silence Mode ON' : 'Silence Mode OFF');
}

function silence_mode_refresh() {
    $.ajax({
        url: '/stargate/get/config',
        type: 'GET',
        cache: false,
        success: function(data) {
            silence_mode_update_button(silence_mode_bool_from_config(data));
        }
    });
}

function silence_mode_apply(turnOn) {
    var enableHardware = !turnOn;
    $.ajax({
        url: '/stargate/update/config',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            audio_enable: enableHardware,
            chevron_motors_enable: enableHardware,
            stepper_motor_enable: enableHardware
        }),
        success: function() {
            silence_mode_update_button(turnOn);
            $.ajax({url: '/stargate/do/restart', type: 'POST'});
            alert(turnOn ? 'Silence Mode ON. Restarting Stargate service.' : 'Silence Mode OFF. Restarting Stargate service.');
        },
        error: function(xhr) {
            alert('Silence Mode update failed: ' + xhr.status);
        }
    });
}

function silence_mode_toggle() {
    var isOn = $('#silenceModeMenuButton').hasClass('silence-mode-on');
    var nextOn = !isOn;
    var message = nextOn
        ? 'Turn Silence Mode ON? Audio, chevron motors and stepper motor will be disabled.'
        : 'Turn Silence Mode OFF? Audio, chevron motors and stepper motor will be enabled.';

    if (confirm(message)) {
        silence_mode_apply(nextOn);
    }
}

function install_silence_mode_menu_button() {
    if ($('#silenceModeMenuButton').length) {
        silence_mode_refresh();
        return;
    }

    var adminToggle = $('#dropdown01');
    var adminMenu = adminToggle.siblings('.dropdown-menu').first();
    if (!adminMenu.length) {
        return;
    }

    var item = $('<a id="silenceModeMenuButton" class="dropdown-item silence-mode-menu-button silence-mode-off" href="#">' +
        '<span class="silence-mode-icon"></span><span class="silence-mode-label">Silence</span></a>');
    item.on('click', function(event) {
        event.preventDefault();
        silence_mode_toggle();
    });

    var configItem = adminMenu.find('a[href="config.htm"], a[href="/config.htm"]').first();
    if (configItem.length) {
        item.insertBefore(configItem);
    } else {
        adminMenu.append(item);
    }

    silence_mode_refresh();
}

$(function() {
    install_silence_mode_menu_button();
});
"""

classic_css_block = r"""
/* Silence Mode menu toggle */
.silence-mode-menu-button {
    align-items: center;
    display: flex !important;
    gap: 0.45rem;
}

.silence-mode-icon {
    border: 2px solid currentColor;
    border-radius: 50%;
    display: inline-block;
    flex: 0 0 auto;
    height: 0.78em;
    width: 0.78em;
}

.silence-mode-off .silence-mode-icon {
    color: #2ecc71;
}

.silence-mode-on .silence-mode-icon {
    color: #ff4d4d;
}

.silence-mode-label {
    text-decoration: none !important;
}
"""

retro_js_block = r"""
async function silenceModeReadConfig() {
    const response = await fetch('/stargate/get/config', {cache: 'no-store'});
    if (!response.ok) {
        throw new Error(`config status ${response.status}`);
    }
    return response.json();
}

function silenceModeFromConfig(configData) {
    const enabled = (name) => configData && configData[name] && configData[name].value === true;
    return !(enabled('audio_enable') || enabled('chevron_motors_enable') || enabled('stepper_motor_enable'));
}

function silenceModeUpdateButton(isOn) {
    const button = document.querySelector('.a-silence-mode');
    if (!button) {
        return;
    }
    button.classList.toggle('silence-mode-on', isOn);
    button.classList.toggle('silence-mode-off', !isOn);
    button.title = isOn ? 'Silence Mode ON' : 'Silence Mode OFF';
}

async function silenceModeRefresh() {
    try {
        const config = await silenceModeReadConfig();
        silenceModeUpdateButton(silenceModeFromConfig(config));
    } catch (error) {
        console.warn('Silence Mode status failed', error);
    }
}

async function silenceModeApply(turnOn) {
    const enableHardware = !turnOn;
    const response = await fetch('/stargate/update/config', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            audio_enable: enableHardware,
            chevron_motors_enable: enableHardware,
            stepper_motor_enable: enableHardware
        })
    });

    if (!response.ok) {
        alert(`Silence Mode update failed: ${response.status}`);
        return;
    }

    silenceModeUpdateButton(turnOn);
    fetch('/stargate/do/restart', {method: 'POST'}).catch(() => {});
    alert(turnOn ? 'Silence Mode ON. Restarting Stargate service.' : 'Silence Mode OFF. Restarting Stargate service.');
}

function silenceModeToggle(event) {
    if (event) {
        event.preventDefault();
    }
    const isOn = document.querySelector('.a-silence-mode')?.classList.contains('silence-mode-on') || false;
    const nextOn = !isOn;
    const message = nextOn
        ? 'Turn Silence Mode ON? Audio, chevron motors and stepper motor will be disabled.'
        : 'Turn Silence Mode OFF? Audio, chevron motors and stepper motor will be enabled.';

    if (confirm(message)) {
        silenceModeApply(nextOn);
    }
}

window.silenceModeToggle = silenceModeToggle;
setTimeout(silenceModeRefresh, 0);
"""

retro_css_block = r"""
/* Silence Mode menu toggle */
.a-silence-mode {
    align-items: center;
    display: flex;
    gap: 0.45em;
}

.silence-mode-dot {
    border: 2px solid currentColor;
    border-radius: 50%;
    display: inline-block;
    height: 0.78em;
    width: 0.78em;
}

.a-silence-mode.silence-mode-off .silence-mode-dot {
    color: #2ecc71;
}

.a-silence-mode.silence-mode-on .silence-mode-dot {
    color: #ff4d4d;
}
"""

top_menu = "web/js/top_menu.js"
if backup(top_menu):
    text = (target / top_menu).read_text(encoding="utf-8")
    text = append_silence_block(text, classic_js_block, "\nfunction silence_mode_bool_from_config(")
    write_text(top_menu, text)
else:
    print(f"Skipped: {top_menu} not found")

main_css = "web/main.css"
if backup(main_css):
    text = (target / main_css).read_text(encoding="utf-8")
    marker = "\n/* Silence Mode menu toggle */"
    start = text.find(marker)
    if start >= 0:
        text = text[:start].rstrip() + "\n"
    text = text.rstrip() + "\n\n" + classic_css_block.strip() + "\n"
    write_text(main_css, text)
else:
    print(f"Skipped: {main_css} not found")

retro_nav = "web/retro/js/navigation.js"
if backup(retro_nav):
    path = target / retro_nav
    text = path.read_text(encoding="utf-8")
    start = text.find("\nasync function silenceModeReadConfig(")
    if start >= 0:
        text = text[:start].rstrip() + "\n"

    if "a-silence-mode" not in text:
        silence_link = "            <a href=\"#\" class=\"a-silence-mode silence-mode-off\" onclick=\"silenceModeToggle(event)\"><span class=\"silence-mode-dot\"></span><span>Silence</span></a>\n"
        candidates = [
            "            <a ${isActive('/config.htm')}>Configuration</a>\n",
            "            <a ${isActive('/retro/info.html')}>System</a>\n",
            "            <a ${isActive('/info.htm')}>System</a>\n",
        ]
        for candidate in candidates:
            if candidate in text:
                text = text.replace(candidate, silence_link + candidate, 1)
                break
        else:
            print("WARNING: Retro Admin menu marker not found; JS status helpers installed, but menu link was not inserted.")

    text = text.rstrip() + "\n\n" + retro_js_block.strip() + "\n"
    write_text(retro_nav, text)
else:
    print(f"Skipped: {retro_nav} not found")

retro_css = "web/retro/css/navigation.css"
if backup(retro_css):
    path = target / retro_css
    text = path.read_text(encoding="utf-8")
    marker = "\n/* Silence Mode menu toggle */"
    start = text.find(marker)
    if start >= 0:
        text = text[:start].rstrip() + "\n"
    source_map = "/*# sourceMappingURL="
    idx = text.find(source_map)
    if idx >= 0:
        text = text[:idx].rstrip() + "\n\n" + retro_css_block.strip() + "\n\n" + text[idx:]
    else:
        text = text.rstrip() + "\n\n" + retro_css_block.strip() + "\n"
    write_text(retro_css, text)
else:
    print(f"Skipped: {retro_css} not found")

print("")
print("=== SILENCE MODE INSTALL COMPLETE ===")
print("Backend Python was not patched.")
print("Silence toggles existing config keys: audio_enable, chevron_motors_enable, stepper_motor_enable.")
print(f"Backup folder: {backup_dir}")
PY
