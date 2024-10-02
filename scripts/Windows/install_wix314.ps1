﻿Write-Host "Installing WiX 3.14.1 ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\wix314.exe"
(New-Object Net.WebClient).DownloadFile('https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait "$exePath" /q
Remove-Item $exePath

Write-Host "WiX 3.14.1 installed" -ForegroundColor Green
