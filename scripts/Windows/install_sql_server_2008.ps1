# https://msdn.microsoft.com/en-us/library/ms144259.aspx
# %programfiles%\Microsoft SQL Server\120\Setup Bootstrap\Log\

Write-Host "Installing SQL Server 2008 R2..." -ForegroundColor Cyan

Write-Host "Downloading..."

$exePath = "$env:USERPROFILE\SQLEXPRADV_x64_ENU.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/0/4/B/04BE03CD-EAF3-4797-9D8D-2E08E316C998/SQLEXPRADV_x64_ENU.exe', $exePath)


Write-Host "Installing..."

cmd /c start /wait $exePath /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2008R2SP2 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /ENABLERANU=1 /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS
del $exePath


Write-Host "Stopping services..."

Set-Service 'MSSQL$SQL2008R2SP2' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'ReportServer$SQL2008R2SP2' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Stop-Service 'MSSQL$SQL2008R2SP2'
Stop-Service 'ReportServer$SQL2008R2SP2'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLWriter'

Write-Host "SQL Server 2008 R2 installed" -ForegroundColor Green