Write-Host "Downloading SQL Server 2017..."
$isoPath = "$env:TEMP\SQLServer2017-x64-ENU-Dev.iso"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU-Dev.iso', $isoPath)

$extractPath = "$env:TEMP\SQLServer2017-x64-ENU-Dev"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\setup.exe /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2017 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

Write-Host "OK"

Write-Host "Downloading SQL Server Reporting Services..."
$reportingPath = "$env:TEMP\SQLServerReportingServices2017.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe', $reportingPath)

Write-Host "Installing..."
cmd /c start /wait $reportingPath /quiet /norestart /IACCEPTLICENSETERMS /Edition=Dev

Write-Host "Deleting temporary files..."
Remove-Item $reportingPath -Force -ErrorAction Ignore

Write-Host "SQL Server 2017 installed" -ForegroundColor Green