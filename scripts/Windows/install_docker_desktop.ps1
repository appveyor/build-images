Write-Host "Installing Docker Desktop 2.2.0.5"

#choco install docker-desktop

Write-Host "Downloading..."
$exePath = "$env:TEMP\Docker-Desktop-Installer.exe"
(New-Object Net.WebClient).DownloadFile('https://download.docker.com/win/stable/43884/Docker%20Desktop%20Installer.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath install --quiet
Remove-Item $exePath

Write-Host "Docker Desktop installed" -ForegroundColor Green

Write-Host "Creating DockerExchange user..."
net user DockerExchange /add

Write-Host "Installing docker-appveyor PowerShell module..."

$dockerAppVeyorPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\docker-appveyor"
New-Item $dockerAppVeyorPath -ItemType Directory -Force

Copy-Item "$PSScriptRoot\docker-appveyor.psm1" -Destination $dockerAppVeyorPath

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

Write-Host "Finished the installation of Docker for Desktop"
