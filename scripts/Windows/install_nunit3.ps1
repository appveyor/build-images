Write-Host "Installing NUnit 3.12.0..." -ForegroundColor Cyan -NoNewline

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$nunitPath = "$env:SYSTEMDRIVE\Tools\NUnit3"

if (Test-Path $nunitPath) {
    Remove-Item $nunitPath -Recurse -Force
}

# nunit
$zipPath = "$env:TEMP\NUnit.Console-3.12.0.zip"
$tempPath = "$env:TEMP\NUnit.Console"
(New-Object Net.WebClient).DownloadFile('https://github.com/nunit/nunit-console/releases/download/v3.12/NUnit.Console-3.12.0.zip', $zipPath)
7z x $zipPath -y -o"$tempPath" | Out-Null
New-Item -Path "$nunitPath" -ItemType Directory -Force | Out-Null
[IO.Directory]::Move("$tempPath\bin\net35", "$nunitPath\bin")
Copy-Item -Path "$tempPath\bin\agents" -Destination $nunitPath -Recurse
Remove-Item $zipPath

# logger
$zipPath = "$($env:TEMP)\Appveyor.NUnit3Logger.zip"
(New-Object Net.WebClient).DownloadFile('https://www.appveyor.com/downloads/Appveyor.NUnit3Logger.zip', $zipPath)
7z x $zipPath -y -o"$nunitPath\bin\addins" | Out-Null
Move-Item "$nunitPath\bin\addins\appveyor.addins" "$nunitPath\bin\appveyor.addins"
Remove-Item $zipPath -Force

Remove-Path "$nunitPath"
Remove-Path "$nunitPath\bin"
Add-Path "$nunitPath\bin"
Add-SessionPath "$nunitPath\bin"

Write-Host "NUnit installed" -ForegroundColor Green