Write-Host "Downloading SQL Server 2019..."
$isoPath = "$env:TEMP\SQLServer2019-x64-ENU-Dev.iso"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-x64-ENU-Dev.iso', $isoPath)

$extractPath = "$env:TEMP\SQLServer2019-x64-ENU-Dev"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\setup.exe /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2019 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

Write-Host "OK"

Write-Host "Downloading SQL Server Reporting Services..."
$reportingPath = "$env:TEMP\SQLServerReportingServices2019.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe', $reportingPath)

Write-Host "Installing..."
cmd /c start /wait $reportingPath /quiet /norestart /IACCEPTLICENSETERMS /Edition=Dev

Write-Host "Deleting temporary files..."
Remove-Item $reportingPath -Force -ErrorAction Ignore

Write-Host "SQL Server 2019 installed" -ForegroundColor Green