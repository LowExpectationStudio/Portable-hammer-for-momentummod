param(
    [switch]$LaunchHammer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:ScriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} elseif ($PSCommandPath) {
    Split-Path -Parent $PSCommandPath
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
}

function Get-PackageRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $script:ScriptRoot ".."))
}

function Get-SteamLibraryRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    $candidateSteamRoots = @(
        (Join-Path ${env:ProgramFiles(x86)} "Steam"),
        (Join-Path $env:ProgramFiles "Steam"),
        "C:\Steam",
        "D:\Steam"
    )

    try {
        $steamReg = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction Stop
        if ($steamReg.SteamPath) {
            $candidateSteamRoots += $steamReg.SteamPath
        }
    } catch {
    }

    foreach ($root in $candidateSteamRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        $fullRoot = [System.IO.Path]::GetFullPath($root)
        if ((Test-Path $fullRoot) -and -not $roots.Contains($fullRoot)) {
            $roots.Add($fullRoot)
        }
    }

    $libraryFoldersFiles = foreach ($root in $roots.ToArray()) {
        Join-Path $root "steamapps\libraryfolders.vdf"
    }

    foreach ($libraryFile in $libraryFoldersFiles) {
        if (-not (Test-Path $libraryFile)) {
            continue
        }

        $content = Get-Content -Raw -Path $libraryFile
        foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
            $path = $match.Groups[1].Value -replace "\\\\", "\"
            if ((Test-Path $path) -and -not $roots.Contains($path)) {
                $roots.Add($path)
            }
        }

        foreach ($match in [regex]::Matches($content, '"\d+"\s+"([^"]+)"')) {
            $path = $match.Groups[1].Value -replace "\\\\", "\"
            if ((Test-Path $path) -and -not $roots.Contains($path)) {
                $roots.Add($path)
            }
        }
    }

    return $roots.ToArray()
}

function Find-MomentumFolder {
    param(
        [string[]]$SteamLibraryRoots
    )

    $candidateCommonNames = @(
        "Momentum Mod Playtest",
        "Momentum Mod"
    )

    foreach ($libraryRoot in $SteamLibraryRoots) {
        $commonRoot = Join-Path $libraryRoot "steamapps\common"
        if (-not (Test-Path $commonRoot)) {
            continue
        }

        foreach ($folderName in $candidateCommonNames) {
            $candidate = Join-Path $commonRoot $folderName
            $momentumFolder = Join-Path $candidate "momentum"
            if (Test-Path $momentumFolder) {
                return [System.IO.Path]::GetFullPath($momentumFolder)
            }
        }

        $genericMatch = Get-ChildItem -Path $commonRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "Momentum Mod*" } |
            ForEach-Object { Join-Path $_.FullName "momentum" } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1

        if ($genericMatch) {
            return [System.IO.Path]::GetFullPath($genericMatch)
        }
    }

    return $null
}

function Find-GarrysModRoot {
    param(
        [string[]]$SteamLibraryRoots
    )

    $candidateNames = @(
        "GarrysMod",
        "Garry's Mod"
    )

    foreach ($libraryRoot in $SteamLibraryRoots) {
        $commonRoot = Join-Path $libraryRoot "steamapps\common"
        if (-not (Test-Path $commonRoot)) {
            continue
        }

        foreach ($folderName in $candidateNames) {
            $candidate = Join-Path $commonRoot $folderName
            $runtimePath = Join-Path $candidate "bin\win64"
            $tier0Path = Join-Path $runtimePath "tier0.dll"
            $vstdlibPath = Join-Path $runtimePath "vstdlib.dll"

            if ((Test-Path $runtimePath) -and (Test-Path $tier0Path) -and (Test-Path $vstdlibPath)) {
                return [System.IO.Path]::GetFullPath($candidate)
            }
        }
    }

    return $null
}

function Read-MomentumFolderFromUser {
    while ($true) {
        Write-Host ""
        Write-Host "Paste the full path to the Momentum Mod 'momentum' folder."
        Write-Host "Example: C:\Program Files (x86)\Steam\steamapps\common\Momentum Mod Playtest\momentum"
        $inputPath = Read-Host "Momentum folder"

        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            Write-Host "A path is required." -ForegroundColor Yellow
            continue
        }

        $trimmed = $inputPath.Trim().Trim('"')
        if (-not (Test-Path $trimmed)) {
            Write-Host "That path does not exist." -ForegroundColor Yellow
            continue
        }

        $resolved = [System.IO.Path]::GetFullPath((Resolve-Path $trimmed).Path)
        $gameInfo = Join-Path $resolved "gameinfo.txt"
        if ((Split-Path $resolved -Leaf) -ieq "momentum" -and (Test-Path $gameInfo)) {
            return $resolved
        }

        Write-Host "The selected folder must be the actual 'momentum' folder and contain gameinfo.txt." -ForegroundColor Yellow
    }
}

function Read-GarrysModRootFromUser {
    while ($true) {
        Write-Host ""
        Write-Host "Paste the full path to the Garry's Mod install folder."
        Write-Host "Example: C:\Program Files (x86)\Steam\steamapps\common\GarrysMod"
        $inputPath = Read-Host "Garry's Mod folder"

        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            Write-Host "A path is required." -ForegroundColor Yellow
            continue
        }

        $trimmed = $inputPath.Trim().Trim('"')
        if (-not (Test-Path $trimmed)) {
            Write-Host "That path does not exist." -ForegroundColor Yellow
            continue
        }

        $resolved = [System.IO.Path]::GetFullPath((Resolve-Path $trimmed).Path)
        $runtimePath = Join-Path $resolved "bin\win64"
        $tier0Path = Join-Path $runtimePath "tier0.dll"
        $vstdlibPath = Join-Path $runtimePath "vstdlib.dll"

        if ((Test-Path $runtimePath) -and (Test-Path $tier0Path) -and (Test-Path $vstdlibPath)) {
            return $resolved
        }

        Write-Host "That folder must contain a 64-bit Garry's Mod runtime in bin\\win64." -ForegroundColor Yellow
    }
}

function New-MountCfgContent {
    param(
        [string]$MomentumPath
    )

    return @(
        "// Portable Hammer++ mount configuration"
        "// Run the setup script again if Momentum Mod moves to a different folder."
        '"mountcfg"'
        "{"
        "    `"momentum`"    `"$MomentumPath`""
        "}"
        ""
    ) -join [Environment]::NewLine
}

function New-PortableGameInfoContent {
    param(
        [string]$GarrysModRoot
    )

    $gmodGamePath = Join-Path $GarrysModRoot "garrysmod"
    $platformPath = Join-Path $GarrysModRoot "platform"
    $sourceEnginePath = Join-Path $GarrysModRoot "sourceengine"
    $gameBinPath = Join-Path $GarrysModRoot "bin"

    return @(
        '"GameInfo"'
        "{"
        '    game    "Garry''s Mod"'
        '    title   ""'
        '    title2  ""'
        '    type    multiplayer_only'
        ""
        '    "developer"         "Facepunch Studios"'
        '    "developer_url"     "http://www.garrysmod.com/"'
        '    "manual"            "http://wiki.garrysmod.com/"'
        ""
        '    "GameData"      "garrysmod.fgd"'
        '    "InstancePath"  "maps/instances/"'
        ""
        '    FileSystem'
        '    {'
        '        SteamAppId              4000'
        '        ToolsAppId              211'
        ""
        '        SearchPaths'
        '        {'
        '            game+mod            "' + $gmodGamePath + '\addons\*"'
        '            game+mod            "' + $gmodGamePath + '\garrysmod.vpk"'
        ""
        '            game                "' + $sourceEnginePath + '\hl2_textures.vpk"'
        '            game                "' + $sourceEnginePath + '\hl2_sound_vo_english.vpk"'
        '            game                "' + $sourceEnginePath + '\hl2_sound_misc.vpk"'
        '            game                "' + $sourceEnginePath + '\hl2_misc.vpk"'
        ""
        '            platform            "' + $platformPath + '\platform_misc.vpk"'
        ""
        '            mod+mod_write+default_write_path        |gameinfo_path|.'
        '            game+game_write     |gameinfo_path|.'
        ""
        '            gamebin             "' + $gameBinPath + '"'
        ""
        '            game                "' + $sourceEnginePath + '"'
        '            platform            "' + $platformPath + '"'
        '            game+download       |gameinfo_path|download'
        '        }'
        '    }'
        '}'
        ""
    ) -join [Environment]::NewLine
}

function Write-PortableGameInfo {
    param(
        [string]$GameInfoPath,
        [string]$GarrysModRoot
    )

    $content = New-PortableGameInfoContent -GarrysModRoot $GarrysModRoot
    if (Test-Path $GameInfoPath) {
        $existing = Get-Content -Raw -Path $GameInfoPath
        if ($existing -ne $content) {
            Copy-Item -Force -Path $GameInfoPath -Destination ($GameInfoPath + ".bak")
        }
    }

    Set-Content -Path $GameInfoPath -Value $content -Encoding ASCII
}

function Sync-GarrysModRuntime {
    param(
        [string]$GarrysModRoot,
        [string]$PortableBinPath
    )

    $sourceRuntimePath = Join-Path $GarrysModRoot "bin\win64"
    if (-not (Test-Path $sourceRuntimePath)) {
        throw "Garry's Mod 64-bit runtime folder not found: $sourceRuntimePath"
    }

    $dlls = Get-ChildItem -Path $sourceRuntimePath -Filter *.dll -File | Sort-Object Name
    if (-not $dlls) {
        throw "No runtime DLLs were found in $sourceRuntimePath"
    }

    $copied = 0
    foreach ($dll in $dlls) {
        $destination = Join-Path $PortableBinPath $dll.Name
        $shouldCopy = $true

        if (Test-Path $destination) {
            $destInfo = Get-Item $destination
            if ($destInfo.Length -eq $dll.Length -and $destInfo.LastWriteTimeUtc -eq $dll.LastWriteTimeUtc) {
                $shouldCopy = $false
            }
        }

        if ($shouldCopy) {
            Copy-Item -Path $dll.FullName -Destination $destination -Force
            $copied++
        }
    }

    return $copied
}

function Update-MountCfg {
    param(
        [string]$MountCfgPath,
        [string]$MomentumPath
    )

    $entryLine = "    `"momentum`"    `"$MomentumPath`""

    if (-not (Test-Path $MountCfgPath)) {
        Set-Content -Path $MountCfgPath -Value (New-MountCfgContent -MomentumPath $MomentumPath) -Encoding ASCII
        return
    }

    $content = Get-Content -Raw -Path $MountCfgPath
    $updated = $content

    if ($content -match '(?ms)"mountcfg"\s*\{') {
        if ($content -match '(?m)^[ \t]*"momentum"[ \t]+"[^"]*"[ \t]*$') {
            $updated = [regex]::Replace(
                $content,
                '(?m)^[ \t]*"momentum"[ \t]+"[^"]*"[ \t]*$',
                [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $entryLine },
                1
            )
        } else {
            $updated = [regex]::Replace(
                $content,
                '(?ms)("mountcfg"\s*\{)(.*?)(\r?\n\})',
                [System.Text.RegularExpressions.MatchEvaluator]{
                    param($m)
                    $body = $m.Groups[2].Value.TrimEnd()
                    if ($body.Length -gt 0) {
                        return $m.Groups[1].Value + $body + [Environment]::NewLine + $entryLine + $m.Groups[3].Value
                    }

                    return $m.Groups[1].Value + [Environment]::NewLine + $entryLine + $m.Groups[3].Value
                },
                1
            )
        }
    } else {
        $updated = $content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + (New-MountCfgContent -MomentumPath $MomentumPath)
    }

    if ($updated -ne $content) {
        Copy-Item -Force -Path $MountCfgPath -Destination ($MountCfgPath + ".bak")
        Set-Content -Path $MountCfgPath -Value $updated -Encoding ASCII
    }
}

$packageRoot = Get-PackageRoot
$portableGamePath = Join-Path $packageRoot "garrysmod"
$mountCfgPath = Join-Path $packageRoot "garrysmod\cfg\mount.cfg"
$gameInfoPath = Join-Path $packageRoot "garrysmod\gameinfo.txt"
$hammerExe = Join-Path $packageRoot "bin\win64\hammerplusplus.exe"
$portableBinPath = Join-Path $packageRoot "bin\win64"

$steamLibraries = Get-SteamLibraryRoots
$detectedGarrysModRoot = Find-GarrysModRoot -SteamLibraryRoots $steamLibraries
$detectedMomentumFolder = Find-MomentumFolder -SteamLibraryRoots $steamLibraries

if ($detectedGarrysModRoot) {
    Write-Host "Detected Garry's Mod 64-bit runtime at:"
    Write-Host "  $detectedGarrysModRoot"
    $useDetectedGmod = Read-Host "Use this path? [Y/n]"
    if ($useDetectedGmod -match '^(n|no)$') {
        $garrysModRoot = Read-GarrysModRootFromUser
    } else {
        $garrysModRoot = $detectedGarrysModRoot
    }
} else {
    Write-Host "Garry's Mod 64-bit runtime was not detected automatically." -ForegroundColor Yellow
    $garrysModRoot = Read-GarrysModRootFromUser
}

if ($detectedMomentumFolder) {
    Write-Host "Detected Momentum Mod content at:"
    Write-Host "  $detectedMomentumFolder"
    $useDetected = Read-Host "Use this path? [Y/n]"
    if ($useDetected -match '^(n|no)$') {
        $momentumFolder = Read-MomentumFolderFromUser
    } else {
        $momentumFolder = $detectedMomentumFolder
    }
} else {
    Write-Host "Momentum Mod was not detected automatically." -ForegroundColor Yellow
    $momentumFolder = Read-MomentumFolderFromUser
}

Update-MountCfg -MountCfgPath $mountCfgPath -MomentumPath $momentumFolder
Write-PortableGameInfo -GameInfoPath $gameInfoPath -GarrysModRoot $garrysModRoot
$copiedDllCount = Sync-GarrysModRuntime -GarrysModRoot $garrysModRoot -PortableBinPath $portableBinPath

Write-Host ""
Write-Host "mount.cfg updated:"
Write-Host "  $mountCfgPath"
Write-Host ""
Write-Host "Momentum mount:"
Write-Host "  $momentumFolder"
Write-Host ""
Write-Host "Garry's Mod runtime source:"
Write-Host "  $garrysModRoot"
Write-Host ""
Write-Host "gameinfo.txt updated:"
Write-Host "  $gameInfoPath"
Write-Host ""
Write-Host "Runtime DLLs synced into portable package:"
Write-Host "  $copiedDllCount file(s) copied or updated"

if ($LaunchHammer) {
    if (-not (Test-Path $hammerExe)) {
        throw "Hammer++ executable not found at $hammerExe"
    }

    Write-Host ""
    Write-Host "Launching Hammer++..."
    Start-Process -FilePath $hammerExe -ArgumentList @("-game", $portableGamePath, "-vproject", $portableGamePath) -WorkingDirectory (Split-Path -Parent $hammerExe)
}
