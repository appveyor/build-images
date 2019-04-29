Write-Host "Installing PostgreSQL 9.5..." -ForegroundColor Cyan

Write-Host "Downloading..."
# http://www.enterprisedb.com/products-services-training/pgdownload#windows
$exePath = "$($env:USERPROFILE)\postgresql-9.5.2-1-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/appveyor-download-cache/postgresql/postgresql-9.5.2-1-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --superpassword Password12!
del $exePath

Write-Host "Setting up services..."
Stop-Service postgresql-x64-9.5
Set-Service -Name postgresql-x64-9.5 -StartupType Manual

Write-Host "PostgreSQL 9.5 installed" -ForegroundColor Green