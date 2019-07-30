$AGENT_VERSION = '7.0.2329'

Write-Host "Installing AppVeyor Build Agent Core"
Write-Host "===================================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destPath = "C:\Program Files\AppVeyor\BuildAgent"

if (Test-Path $destPath) {
	Remove-Item $destPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\appveyor-build-agent.zip"
(New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/appveyor/$AGENT_VERSION/appveyor-build-agent-$AGENT_VERSION-win-x64.zip", $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -o"$destPath" | Out-Null

Remove-Item $zipPath -Force

Write-Host "AppVeyor Build Agent installed"