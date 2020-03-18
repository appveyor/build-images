Write-Host "Installing SQL Server 2012 SP1..." -ForegroundColor Cyan

Write-Host "Downloading..."

$exePath = "$env:TEMP\SQLEXPRADV_x64_ENU.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/5/2/9/529FEF7B-2EFB-439E-A2D1-A1533227CD69/SQLEXPRADV_x64_ENU.exe', $exePath)


Write-Host "Installing..."

cmd /c start /wait $exePath /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2012SP1 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /ENABLERANU=1 /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS
del $exePath


Write-Host "Stopping services..."

Set-Service 'MSSQL$SQL2012SP1' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'ReportServer$SQL2012SP1' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Stop-Service 'MSSQL$SQL2012SP1'
Stop-Service 'ReportServer$SQL2012SP1'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLWriter'

Write-Host "SQL Server 2012 SP1 installed" -ForegroundColor Green