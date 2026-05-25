# Silence Mode

Adds an Admin menu Silence toggle using existing config.htm hardware switches.

This repository is private while it is being checked and verified.

## Install

```bash
cd /home/pi/Stargate-Final_Patches
rm -rf Silence-Mode
git clone https://github.com/matelv-x/Silence-Mode.git
cd Silence-Mode
chmod +x *.sh
sudo ./install.sh --target /home/pi/sg1_v4
sudo systemctl restart stargate.service
```

## Restore / uninstall

```bash
cd /home/pi/Stargate-Final_Patches/Silence-Mode
chmod +x restore.sh
sudo ./restore.sh --target /home/pi/sg1_v4
sudo systemctl restart stargate.service
```

## What it changes

- Adds Silence button to classic and Retro Admin menus.
- Toggles audio_enable, chevron_motors_enable and stepper_motor_enable.
- Does not patch classes/web_server.py.

## Attribution and originality

Original base project: StargateProject SG1 software from the BuildAStargate/Jordan/Kristian/Jonnerd project lineage.

Additional source/idea credit: Feature idea by Marcin/Codex, using the existing StargateProject config API and config.htm behavior.

How much is copied or changed: Small UI patch. It only patches web menu JS/CSS and includes command-line fallback scripts.

The included `*.patch` file, when present, shows the exact text-level changes against the base software used while packaging.
