Write-Host "Installing Chrome..." -ForegroundColor Cyan

choco install googlechrome --version=78.0.3904.87

Set-Service gupdate -StartupType Manual

Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineCore -Confirm:$false
Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineUA -Confirm:$false

Write-Host "Installed Chrome" -ForegroundColor Green