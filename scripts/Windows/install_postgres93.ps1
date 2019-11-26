Write-Host "Installing PostgreSQL 9.3..." -ForegroundColor Cyan

Write-Host "Downloading..."
# http://www.enterprisedb.com/products-services-training/pgdownload#windows
$exePath = "$env:TEMP\postgresql-9.3.10-1-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('http://get.enterprisedb.com/postgresql/postgresql-9.3.10-1-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --superpassword Password12!
del $exePath

Write-Host "Setting up services..."
Stop-Service postgresql-x64-9.3
Set-Service -Name postgresql-x64-9.3 -StartupType Manual

Write-Host "PostgreSQL 9.3 installed" -ForegroundColor Green