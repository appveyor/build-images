Write-Host "Installing PostgreSQL 9.4..." -ForegroundColor Cyan

Write-Host "Downloading..."
# http://www.enterprisedb.com/products-services-training/pgdownload#windows
$exePath = "$($env:USERPROFILE)\postgresql-9.4.7-1-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('http://get.enterprisedb.com/postgresql/postgresql-9.4.7-1-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --superpassword Password12!
del $exePath

Write-Host "Setting up services..."
Stop-Service postgresql-x64-9.4
Set-Service -Name postgresql-x64-9.4 -StartupType Manual

Write-Host "PostgreSQL 9.4 installed" -ForegroundColor Green