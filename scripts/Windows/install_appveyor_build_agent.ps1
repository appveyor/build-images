Write-Host "Installing AppVeyor Build Agent"
Write-Host "==============================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destPath = "$env:ProgramFiles\AppVeyor\BuildAgent"

Write-Host "Downloading..."
$zipPath = "$env:TEMP\appveyor-build-agent.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/appveyor/ci/releases/download/build-agent-v6.1.0%2B1300/AppveyorBuildAgent.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -o"$destPath" | Out-Null

Remove-Item $zipPath -Force

# Add build agent settings
New-Item "HKLM:\Software\AppVeyor" -Name "Build Agent" -Force | Out-Null
Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "AppVeyorUrl" -Value 'https://ci.appveyor.com'
Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "Mode" -Value $env:build_agent_mode

# Enable auto load on system start
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "Run" -Force | Out-Null

Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
	-Value 'powershell -File "C:\Program Files\AppVeyor\BuildAgent\update-appveyor-agent.ps1"'

Write-Host "AppVeyor Build Agent installed"
