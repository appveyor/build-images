. "$PSScriptRoot\common.ps1"
# 149.0.7827.22
Write-Host "Installing Chrome..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\googlechromestandaloneenterprise64.msi"
(New-Object Net.WebClient).DownloadFile('https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /qn /norestart
Remove-Item $msiPath

Set-Service gupdate -StartupType Manual -ErrorAction SilentlyContinue
Set-Service gupdatem -StartupType Manual -ErrorAction SilentlyContinue

Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineCore -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineUA -Confirm:$false -ErrorAction SilentlyContinue

Start-Sleep -s 5
GetProductVersion "Chrome"

Write-Host "Installed Chrome" -ForegroundColor Green
