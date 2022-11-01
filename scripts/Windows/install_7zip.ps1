﻿Write-Host "Installing 7-Zip"
Write-Host "================"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$exePath = "$env:TEMP\7z2201-x64.exe"
Invoke-WebRequest "https://www.7-zip.org/a/7z2201-x64.exe" -OutFile $exePath
cmd /c start /wait $exePath /S
del $exePath

$sevenZipFolder = "${env:ProgramFiles}\7-Zip"
Add-SessionPath $sevenZipFolder
Add-Path "$sevenZipFolder"

[Environment]::SetEnvironmentVariable("7zip", "`"$sevenZipFolder\7z.exe`"", "Machine")

Write-Host "7-Zip installed"