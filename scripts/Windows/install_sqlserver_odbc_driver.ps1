Write-Host "Installing ODBC driver 18..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\msodbcsql.msi"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/c/5/4/c54c2bf1-87d0-4f6f-b837-b78d34d4d28a/en-US/18.2.1.1/x64/msodbcsql.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
Remove-Item $msiPath

Write-Host "ODBC version 18 installed" -ForegroundColor Green


