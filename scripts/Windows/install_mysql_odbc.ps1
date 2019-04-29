Write-Host "Installing MySQL ODBC driver ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$($env:USERPROFILE)\mysql-connector-odbc-5.3.4-winx64.msi"
(New-Object Net.WebClient).DownloadFile('https://dev.mysql.com/get/Downloads/Connector-ODBC/5.3/mysql-connector-odbc-5.3.4-winx64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
del $msiPath

Write-Host "MySQL ODBC driver installed" -ForegroundColor Green
