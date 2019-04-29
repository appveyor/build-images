Write-Host "Installing NUnit 3.9.0..." -ForegroundColor Cyan -NoNewline

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit3"

Remove-Item $nunitPath -Recurse -Force

# nunit
$zipPath = "$($env:TEMP)\NUnit.Console-3.9.0.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/nunit/nunit-console/releases/download/v3.9/NUnit.Console-3.9.0.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath" | Out-Null
del $zipPath

# logger
$zipPath = "$($env:TEMP)\Appveyor.NUnit3Logger.zip"
(New-Object Net.WebClient).DownloadFile('https://www.appveyor.com/downloads/Appveyor.NUnit3Logger.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\addins" | Out-Null
Move-Item "$nunitPath\addins\appveyor.addins" "$nunitPath\appveyor.addins"
Remove-Item $zipPath -Force

Remove-Path "$nunitPath\bin"
Add-Path "$nunitPath"

Write-Host "NUnit 3.9.0 installed" -ForegroundColor Green