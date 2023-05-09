Write-Host "Downloading SQL Server 2022..."
$isoPath = "$env:TEMP\SQLServer2022-x64-ENU-Dev.iso"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLServer2022-x64-ENU-Dev.iso', $isoPath)

$extractPath = "$env:TEMP\SQLServer2022-x64-ENU-Dev"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\setup.exe /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS,SSMS /INSTANCENAME=SQL2022 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /NPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

Write-Host "OK"

Write-Host "Downloading SQL Server Reporting Services..."
$reportingPath = "$env:TEMP\SQLServerReportingServices2022.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/8/3/2/832616ff-af64-42b5-a0b1-5eb07f71dec9/SQLServerReportingServices.exe', $reportingPath)

Write-Host "Installing..."
cmd /c start /wait $reportingPath /quiet /norestart /IACCEPTLICENSETERMS /Edition=Dev

Write-Host "Deleting temporary files..."
Remove-Item $reportingPath -Force -ErrorAction Ignore

Write-Host "SQL Server 2022 installed" -ForegroundColor Green


