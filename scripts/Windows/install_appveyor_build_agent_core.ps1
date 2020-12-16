$AGENT_VERSION = '7.0.2883'

if ($env:AGENT_VERSION) {
	$AGENT_VERSION = $env:AGENT_VERSION
}

Write-Host "Installing AppVeyor Build Agent Core"
Write-Host "===================================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destPath = "$env:ProgramFiles\AppVeyor\BuildAgent"

if ($env:AGENT_INSTALL_DIR) {
	$destPath = $env:AGENT_INSTALL_DIR
}

Write-Host "Installing Build Agent Core version $AGENT_VERSION to '$destPath'"

if (Test-Path $destPath) {
	Remove-Item $destPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\appveyor-build-agent.zip"
(New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/appveyor/$AGENT_VERSION/appveyor-build-agent-$AGENT_VERSION-win-x64.zip", $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -o"$destPath" | Out-Null

Remove-Item $zipPath -Force

# Add build agent settings

Write-Host "Agent mode: $($env:BUILD_AGENT_MODE)"

New-Item "HKLM:\Software\AppVeyor" -Name "BuildAgent" -Force | Out-Null
if ($env:appveyor_url) {$appVeyorUrl = $env:appveyor_url} else {$appVeyorUrl = 'https://ci.appveyor.com'}
Set-ItemProperty "HKLM:\Software\AppVeyor\BuildAgent" -Name "AppVeyorUrl" -Value $appVeyorUrl
Set-ItemProperty "HKLM:\Software\AppVeyor\BuildAgent" -Name "Mode" -Value $env:BUILD_AGENT_MODE
Set-ItemProperty "HKLM:\Software\AppVeyor\BuildAgent" -Name "ProjectBuildsDirectory" -Value ""

# Enable auto load on system start
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "Run" -Force | Out-Null

Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
	-Value "$destPath\appveyor-build-agent.exe"

Write-Host "AppVeyor Build Agent installed"