Write-Host "Installing MinGW..." -ForegroundColor Cyan

$mingwPath = "C:\mingw-w64"

# MinGW 8.1

$destPath = "$mingwPath\x86_64-8.1.0-posix-seh-rt_v6-rev0"
$zipPath = "$env:TEMP\mingw-w64.7z"
(New-Object Net.WebClient).DownloadFile('https://iweb.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z', $zipPath)
7z x $zipPath -o"$destPath" -aoa
Remove-Item $zipPath

Write-Host "Installed MinGW" -ForegroundColor Green