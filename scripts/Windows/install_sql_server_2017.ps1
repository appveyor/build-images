Write-Host "Downloading SQL Server 2017..."
$boxPath = "$env:USERPROFILE\SQLServer2017-DEV-x64-ENU.box"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-DEV-x64-ENU.box', $boxPath)
$exePath = "$env:USERPROFILE\SQLServer2017-DEV-x64-ENU.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-DEV-x64-ENU.exe', $exePath)

Write-Host "Extracting..."
$extractPath = "$env:TEMP\SQL2017Developer"
Start-Process "$exePath" "/Q /x:`"$extractPath`"" -Wait

Write-Host "Installing..."
cmd /c start /wait $extractPath\setup.exe /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2017 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Deleting temporary files..."
Remove-Item $exePath -Force -ErrorAction Ignore
Remove-Item $boxPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

Write-Host "OK"

Write-Host "Downloading SQL Server Reporting Services..."
$reportingPath = "$env:TEMP\SQLServerReportingServices.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe', $reportingPath)

Write-Host "Installing..."
cmd /c start /wait $reportingPath /quiet /norestart /IACCEPTLICENSETERMS /Edition=Dev

Write-Host "Deleting temporary files..."
Remove-Item $reportingPath -Force -ErrorAction Ignore

Write-Host "OK"

