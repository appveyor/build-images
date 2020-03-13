. "$PSScriptRoot\common.ps1"

Write-Host "Installing Chrome..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\googlechromestandaloneenterprise64.msi"
(New-Object Net.WebClient).DownloadFile('https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet /norestart
del $msiPath

Set-Service gupdate -StartupType Manual -ErrorAction SilentlyContinue
Set-Service gupdatem -StartupType Manual -ErrorAction SilentlyContinue

Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineCore -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineUA -Confirm:$false -ErrorAction SilentlyContinue

GetProductVersion "Chrome"

Write-Host "Installed Chrome" -ForegroundColor Green