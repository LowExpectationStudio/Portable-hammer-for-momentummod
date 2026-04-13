Momentum Mod Hammer++ Portable
==============================

What this is
- A separate portable Hammer++ package layout and setup script based on the Garry's Mod Hammer++ build.
- It does not modify Momentum Mod's built-in Hammer or Strata Hammer.
- It does not modify Garry's Mod's built-in tools either.
- It does not copy files into Momentum Mod.
- You can delete this folder later without affecting Momentum Mod.

Repository note
- This repository is public so people can inspect the setup scripts and packaging logic.
- The upstream Hammer++ binaries are third-party files and are not claimed as open source by this repository.
- The public repository intentionally excludes the bundled "bin" folder.
- To use this package from the repository, copy in the Hammer++ Garry's Mod build's "bin" folder yourself before first run.

First run
1. Extract this folder anywhere.
2. Double-click "Launch Hammer++ with momentum mounted.bat".
3. The setup script will try to detect your Momentum Mod install automatically.
4. If it cannot find it, paste the full path to your Momentum Mod "momentum" folder.
5. The script also detects your Garry's Mod 64-bit install.
6. It writes the Momentum path into "garrysmod\\cfg\\mount.cfg" inside this portable folder.
7. It writes a portable "garrysmod\\gameinfo.txt" that points back to your real Garry's Mod content.
8. It copies the required runtime DLLs from your own Garry's Mod install into this portable folder.
9. Hammer++ launches with explicit "-game" and "-vproject" arguments pointing to this portable folder's own "garrysmod" directory.

Manual configure only
- If you only want to write or update the mount path without launching Hammer++, run "momentum mount - do this first.bat".

Expected Momentum path
- Typical Steam install:
  C:\Program Files (x86)\Steam\steamapps\common\Momentum Mod Playtest\momentum

What the setup script does
- Reads Steam library locations from common Steam paths and from "steamapps\\libraryfolders.vdf" when available.
- Detects a Garry's Mod install with a valid 64-bit runtime in "bin\\win64".
- Looks for "Momentum Mod Playtest\\momentum" first, then other "Momentum Mod*" folders.
- Writes only the "momentum" mount entry inside this package's own "garrysmod\\cfg\\mount.cfg".
- Writes this package's own "garrysmod\\gameinfo.txt" so Hammer++ can use local config while reading Garry's Mod content from the real install.
- Copies runtime DLLs from "GarrysMod\\bin\\win64" into this package's own "bin\\win64" folder.
- Preserves other existing mount.cfg entries when possible.
- Creates "mount.cfg.bak" before changing an existing mount.cfg.

Important notes
- This package is isolated from Momentum Mod. It does not overwrite Momentum files.
- This package still requires local installs of both Momentum Mod and 64-bit Garry's Mod.
- If you move Momentum Mod to a different Steam library later, run the launcher again so mount.cfg gets updated.
- The original Hammer++ readme from the download is included as:
  docs\\UPSTREAM-HammerPP-README.txt

Files you will likely use
- Launch Hammer++ with momentum mounted.bat
- momentum mount - do this first.bat
- garrysmod\\cfg\\mount.cfg
- tools\\Setup-MomentumMount.ps1
