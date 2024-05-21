Write-Host "Installing PostgreSQL 16..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\postgresql-16.3-1-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('https://get.enterprisedb.com/postgresql/postgresql-16.3-1-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --install_runtimes 0 --superpassword Password12!
Remove-Item $exePath -ErrorAction SilentlyContinue

Write-Host "Setting up services..."
Stop-Service postgresql-x64-16
Set-Service -Name postgresql-x64-16 -StartupType Manual

Write-Host "PostgreSQL 16 installed" -ForegroundColor Green