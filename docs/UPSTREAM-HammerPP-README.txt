--- Install instructions ---
This build of Hammer++ only works with 64-bit Garry's Mod.

0. Ensure you are on the "x86-64" (64-bit) branch of Garry's Mod.
   You can enable this by right clicking on Garry's Mod in Steam, 
   Properties -> Betas -> Change "Beta Participation" to "x86-64 - Chromium + 64-bit binaries"
   
   Hammer++ will NOT work on any other version.

1. Find where Garry's Mod is installed

2. Copy over everything inside this download's "bin" folder into Garry Mod's "bin" folder.
	Your paths should look like this:
	<steam install location>/steamapps/common/Garry's Mod/bin/win64/hammerplusplus.exe
	<steam install location>/steamapps/common/Garry's Mod/bin/win64/hammerplusplus/<other files>
	
3. Launch the Hammer++ exe, and you are done!

-- Troublshooting --
If you get an application error with code 0xc0000007b, you installed the files into the wrong 32-bit folder.
Tthe files must go into the "win64" folder inside "bin".
	
--- Other Information ---
If you want to mount content from other games such as Counter Strike Source, you can use Garry's Mod's "mount.cfg" feature.
This mount.cfg file is located in the "Garry's Mod/garrysmod/cfg/" folder. Open it in Notepad and follow the instructions.

Hammer++ does not use the GameConfig.txt, instead it uses its own GameConfig.txt located in the hammerplusplus sub folder. 
If not found, it copies the normal game configuration.
Keep this in mind when following any tutorials.

HLMV++ comes bundled with the download, it is optional and not required for Hammer++ to work.

--- Uninstallation ---
To uninstall, simply delete the hammerplusplus.exe
You can also optionally delete the hammerplusplus folder, but this will remove all saved settings for Hammer++.
