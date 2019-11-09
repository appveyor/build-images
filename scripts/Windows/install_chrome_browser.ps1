Write-Host "Installing Chrome..." -ForegroundColor Cyan

choco install googlechrome --ignore-checksums

Set-Service gupdate -StartupType Manual

Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineCore -Confirm:$false
Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineUA -Confirm:$false

Write-Host "Installed Chrome" -ForegroundColor Green