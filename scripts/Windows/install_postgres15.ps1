﻿#Write-Host "Pre-installing vcredist2015 (PostgreSQL 10.6 instalation has issues when doing it)..." -ForegroundColor Cyan
#choco install vcredist2015

Write-Host "Installing PostgreSQL 15..." -ForegroundColor Cyan

Write-Host "Downloading..."
# http://www.enterprisedb.com/products-services-training/pgdownload#windows
$exePath = "$env:TEMP\postgresql-15.2-2-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('https://get.enterprisedb.com/postgresql/postgresql-15.2-2-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --install_runtimes 0 --superpassword Password12!
Remove-Item $exePath -ErrorAction SilentlyContinue

Write-Host "Setting up services..."
Stop-Service postgresql-x64-15
Set-Service -Name postgresql-x64-15 -StartupType Manual

Write-Host "PostgreSQL 15 installed" -ForegroundColor Green