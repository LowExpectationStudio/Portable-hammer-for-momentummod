# Momentum Mod Hammer++ Portable

Public packaging scripts for a separate portable Hammer++ setup that uses the Garry's Mod Hammer++ build as its base and mounts Momentum Mod content through `garrysmod/cfg/mount.cfg`.

## What this repo contains
- PowerShell setup script for first-run detection and config generation
- Batch launchers for configure-only and launch flows
- Portable `mount.cfg` and `gameinfo.txt` templates
- README and upstream reference notes

## What this repo does not contain
- The upstream Hammer++ `bin` payload
- Garry's Mod runtime binaries
- Momentum Mod files

Those files are intentionally excluded. The checked-in templates use placeholder paths on purpose, and the setup script rewrites them locally for each user on first run.

## How to use
1. Download the Garry's Mod Hammer++ build from:
   https://ficool2.github.io/HammerPlusPlus-Website/download.html
2. Copy its `bin` folder into this package folder.
3. Run `momentum mount - do this first.bat` or `Launch Hammer++ with momentum mounted.bat`.
4. Let the script detect Garry's Mod and Momentum Mod, or enter the paths manually.

## Safety / transparency
This repository is public so the setup logic can be inspected. It does not claim the third-party Hammer++ binaries are open source.

## Repository
https://github.com/LowExpectationStudio/Portable-hammer-for-momentummod
