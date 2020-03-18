Write-Host "Installing AppVeyor Build Agent"
Write-Host "==============================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destPath = "$env:ProgramFiles\AppVeyor\BuildAgent"

$versionFeedUrl = 'https://appveyordownloads.blob.core.windows.net/build-agent/appveyor-build-agent-windows-version-6.0.txt'

if ($env:build_agent_version_feed_url) {
    $versionFeedUrl = $env:build_agent_version_feed_url
}

Write-Host "Querying for the latest version of Build Agent from $versionFeedUrl"
$versionInfo = (New-Object Net.WebClient).DownloadString($versionFeedUrl).split(' ')
Write-Host "Installing Build Agent version $($versionInfo[0])"

Write-Host "Downloading..."
$zipPath = "$env:TEMP\appveyor-build-agent.zip"
(New-Object Net.WebClient).DownloadFile($versionInfo[1], $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -o"$destPath" | Out-Null

Remove-Item $zipPath -Force

# Add build agent settings
New-Item "HKLM:\Software\AppVeyor" -Name "Build Agent" -Force | Out-Null
Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "AppVeyorUrl" -Value 'https://ci.appveyor.com'
Set-ItemProperty "HKLM:\Software\AppVeyor\Build Agent" -Name "Mode" -Value $env:build_agent_mode

# Enable auto load on system start
if (-not (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run')) {
    New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "Run" -Force | Out-Null
}

Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "AppVeyor.BuildAgent" `
	-Value "powershell -File `"${env:ProgramFiles}\AppVeyor\BuildAgent\update-appveyor-agent.ps1`""

# Make PS modules visible to external PS sessions
$AppVeyorModulesPath = "$destPath\Modules"
$PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
if(-not $PSModulePath.contains($AppVeyorModulesPath)) {
    [Environment]::SetEnvironmentVariable('PSModulePath', "$PSModulePath;$AppVeyorModulesPath", 'Machine')
}

Write-Host "AppVeyor Build Agent installed"
