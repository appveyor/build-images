Write-Host "Installing AWS PowerShell ..." -ForegroundColor Cyan

Install-Module -Name AWSPowerShell -Force

Write-Host "Installed" -ForegroundColor Green

# test installation
Get-Command Get-S3Bucket