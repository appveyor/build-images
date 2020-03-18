Write-Host "Installing PostgreSQL ODBC drivers..." -ForegroundColor Cyan

Write-Host "Downloading..."
$zipPath = "$env:TEMP\psqlodbc_09_03_0300-x64-1.zip"
$zipOut = "$env:TEMP\psqlodbc"
(New-Object Net.WebClient).DownloadFile('https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_03_0300-x64-1.zip', $zipPath)

Write-Host "Unpacking..."
7z x $zipPath -y -o"$zipOut" | Out-Null
del $zipPath

$msiPath = "$zipOut\psqlodbc_x64.msi"
cmd /c start /wait msiexec /i $msiPath /q

Remove-Item $zipOut -Recurse -Force

Write-Host "PostgreSQL ODBC drivers installed" -ForegroundColor Green