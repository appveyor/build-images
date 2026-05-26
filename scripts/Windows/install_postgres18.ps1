Write-Host "Installing PostgreSQL 18..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\postgresql-18.4-1-windows-x64.exe"
(New-Object Net.WebClient).DownloadFile('https://get.enterprisedb.com/postgresql/postgresql-18.4-1-windows-x64.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath --mode unattended --install_runtimes 0 --superpassword Password12!
Remove-Item $exePath -ErrorAction SilentlyContinue

Write-Host "Setting up services..."
Stop-Service postgresql-x64-18
Set-Service -Name postgresql-x64-18 -StartupType Manual

Write-Host "PostgreSQL 18 installed" -ForegroundColor Green
