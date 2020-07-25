﻿# https://www.doxygen.nl/download.html

Write-Host "Installing Doxygen..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Doxygen'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:TEMP\doxygen.zip"
(New-Object Net.WebClient).DownloadFile('http://doxygen.nl/files/doxygen-1.8.18.windows.x64.bin.zip', $zipPath)
7z x $zipPath -aoa -o"$destPath"
Remove-Item $zipPath

Add-Path $destPath
Add-SessionPath $destPath

cmd /c doxygen --version

Write-Host "Installed Doxygen" -ForegroundColor Green