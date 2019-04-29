Write-Host "Installing MSMQ..." -ForegroundColor Cyan

Install-WindowsFeature "MSMQ-Server"

Write-Host "Disabling services..."
Stop-Service MSMQ

Set-Service MSMQ -StartupType Manual


Write-Host "MSMQ installed" -ForegroundColor Green