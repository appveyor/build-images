Write-Host "Installing MinGW-w64..." -ForegroundColor Cyan

$mingwPath = "$env:systemdrive\mingw-w64"

if (Test-Path $mingwPath) {
    Remove-Item $mingwPath -Force -Recurse
}
New-Item $mingwPath -ItemType Directory -Force | Out-Null

# MinGW 8.1

$destPath = "$mingwPath\x86_64-8.1.0-posix-seh-rt_v6-rev0"
$zipPath = "$env:TEMP\mingw-w64.7z"
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z', $zipPath)
7z x $zipPath -o"$destPath" -aoa
Remove-Item $zipPath

$destPath = "$mingwPath\i686-8.1.0-posix-dwarf-rt_v6-rev0"
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/i686-8.1.0-release-posix-dwarf-rt_v6-rev0.7z', $zipPath)
7z x $zipPath -o"$destPath" -aoa
Remove-Item $zipPath

Write-Host "Installed MinGW-w64" -ForegroundColor Green
