Write-Host "Installing NUnit 2.7.1..." -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit"

Remove-Item $nunitPath -Recurse -Force -ErrorAction SilentlyContinue

# nunit
$zipPath = "$env:TEMP\NUnit-2.7.1.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/nunit-legacy/nunitv2/releases/download/2.7.1/NUnit-2.7.1.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath" | Out-Null
Remove-Item $zipPath

# logger
$zipPath = "$env:TEMP\Appveyor.NUnitLogger.zip"
(New-Object Net.WebClient).DownloadFile('http://www.appveyor.com/downloads/Appveyor.NUnitLogger.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\bin\addins" | Out-Null
Remove-Item $zipPath

Add-Path "$nunitPath\bin"

Write-Host "NUnit installed" -ForegroundColor Green