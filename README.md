# Silence Mode UI

[![Downloads](https://img.shields.io/github/downloads/matelv-x/Silence-Mode/total?label=downloads)](https://github.com/matelv-x/Silence-Mode/releases)

Adds a Silence button to classic and Retro Admin menus using existing config keys.

## Install

Clone or unzip this add-on into `/home/pi`, then run:

```bash
cd /home/pi
rm -rf Silence-Mode
git clone https://github.com/matelv-x/Silence-Mode.git
cd Silence-Mode
chmod +x *.sh
sudo ./install.sh --target /home/pi/sg1_v4
sudo systemctl restart stargate.service
```

## Restore / uninstall

```bash
cd /home/pi/Silence-Mode
sudo ./restore.sh --target /home/pi/sg1_v4
sudo systemctl restart stargate.service
```

## What it changes

- Toggles `audio_enable`, `chevron_motors_enable`, and `stepper_motor_enable`.
- Does not patch `classes/web_server.py`.
- Includes `silence_on.sh`, `silence_off.sh`, and `status.sh`.

## Attribution and originality

Original base project: StargateProject SG1 software from the BuildAStargate/Jordan/Kristian/Jonnerd project lineage.

Additional source/idea credit: Feature idea by matelv-x/Codex using existing StargateProject config API behavior.

Retro UI credit: When this add-on patches the Retro Admin menu, that Retro UI/menu code comes from the Polklabs project:
https://github.com/polklabs/stargate-retro

matelv-x/Codex modification: this repository adds the Silence on/off UI and scripts, then places the control into classic and Polklabs-derived Retro menus when available.

How much is copied or changed: Small UI/config patch only.
