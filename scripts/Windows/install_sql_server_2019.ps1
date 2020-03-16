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

Write-Host "Preparing SQL Server 2019..."

Write-Host "Stopping services..."

Stop-Service 'MSSQL$SQL2019'
Stop-Service 'MSSQLFDLauncher$SQL2019'
Stop-Service 'SQLAgent$SQL2019'
Stop-Service 'MSOLAP$SQL2019' -ErrorAction Ignore
Stop-Service 'SSASTELEMETRY$SQL2019' -ErrorAction Ignore
Stop-Service 'SQLTELEMETRY$SQL2019'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLServerReportingServices'
Stop-Service 'SQLWriter'

Write-Host "Changing services startup mode..."

Set-Service 'MSSQL$SQL2019' -StartupType Manual
Set-Service 'MSSQLFDLauncher$SQL2019' -StartupType Manual
Set-Service 'SQLAgent$SQL2019' -StartupType Manual
Set-Service 'MSOLAP$SQL2019' -StartupType Manual -ErrorAction Ignore
Set-Service 'SSASTELEMETRY$SQL2019' -StartupType Manual -ErrorAction Ignore
Set-Service 'SQLTELEMETRY$SQL2019' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'SQLServerReportingServices' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Write-Host "Updating SQL Server TCP/IP configuration..."

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'SQL2019'
$computerName = $env:COMPUTERNAME
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = New-Object ($smo + 'Wmi.ManagedComputer')

# For the named instance, on the current computer, for the TCP protocol,
# loop through all the IPs and configure them to use the standard port
# of 1433.
$uri = "ManagedComputer[@Name='$computerName']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
ForEach ($ipAddress in $Tcp.IPAddresses)
{
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
}
$Tcp.IsEnabled = $true
$Tcp.Alter()

# Start services
Write-Host "Trying to start SQL Server service..."
Start-Service SQLBrowser
Start-Service "MSSQL`$$instanceName"

Write-Host "Stopping SQL Server service..."
Stop-Service "MSSQL`$$instanceName"
Stop-Service "MSSQLFDLauncher`$$instanceName" -ErrorAction SilentlyContinue
Stop-Service SQLBrowser

Write-Host "SQL Server 2019 installed and configured" -ForegroundColor Green

