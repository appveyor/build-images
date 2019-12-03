choco install docker-desktop

Write-Host "Creating DockerExchange user..."
net user DockerExchange /add

Write-Host "Installing docker-appveyor PowerShell module..."

$dockerAppVeyorPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\docker-appveyor"
New-Item $dockerAppVeyorPath -ItemType Directory -Force

Copy-Item "$env:TEMP\docker-appveyor.psm1" -Destination $dockerAppVeyorPath

Remove-Module docker-appveyor -ErrorAction SilentlyContinue
Import-Module docker-appveyor

$UserModulesPath = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
$PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
if(-not $PSModulePath.contains($UserModulesPath)) {
    [Environment]::SetEnvironmentVariable('PSModulePath', "$PSModulePath;$UserModulesPath", 'Machine')
}

Write-Host "Mapping docker-switch-windows.cmd to Switch-DockerWindows..."

@"
@echo off
powershell -command "Switch-DockerWindows"
"@ | Set-Content -Path "$env:ProgramFiles\Docker\Docker\resources\bin\docker-switch-windows.cmd"

Write-Host "Mapping docker-switch-linux.cmd to Switch-DockerLinux..."

@"
@echo off
powershell -command "Switch-DockerLinux"
"@ | Set-Content -Path "$env:ProgramFiles\Docker\Docker\resources\bin\docker-switch-linux.cmd"

Write-Host "Done"

Write-Host "Setting up final docker steps to run at RunOnce"

# Prepare docker on the next start
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "RunOnce" -Force | Out-Null

Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "!prepare-docker" -Value "powershell -File `"$env:USERPROFILE\prepare-docker.ps1`""

Write-Host "Done"
