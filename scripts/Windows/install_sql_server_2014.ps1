Write-Host "Installing SQL Server 2014 SP1..." -ForegroundColor Cyan

# Install manually from:
# https://download.microsoft.com/download/1/5/6/156992E6-F7C7-4E55-833D-249BD2348138/ENU/x64/SQLEXPRADV_x64_ENU.exe

<#
Write-Host "Downloading..."

$exePath = "$env:TEMP\SQLEXPRADV_x64_ENU.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/5/6/156992E6-F7C7-4E55-833D-249BD2348138/ENU/x64/SQLEXPRADV_x64_ENU.exe', $exePath)


Write-Host "Installing..."

cmd /c start /wait $exePath /q /ACTION=Install /FEATURES=SQLEngine,FullText,RS /INSTANCENAME=SQL2014 /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /ENABLERANU=1 /TCPENABLED=1 /SECURITYMODE=SQL /SAPWD=Password12! /IACCEPTSQLSERVERLICENSETERMS
del $exePath
#>

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'sql2014'
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
Set-Service SQLBrowser -StartupType Manual
Start-Service SQLBrowser
Restart-Service "MSSQL`$$instanceName"




Write-Host "Stopping services..."

Set-Service 'MSSQL$SQL2014' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'ReportServer$SQL2014' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Stop-Service 'MSSQL$SQL2014'
Stop-Service 'ReportServer$SQL2014'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLWriter'

Write-Host "SQL Server 2014 installed" -ForegroundColor Green

<#

net start MSSQL$SQL2014
sqlcmd -S (local)\SQL2014 -U sa -P Password12! -Q "SELECT name from sys.databases"
net stop MSSQL$SQL2014

sqllocaldb create "test" 12.0 -s
sqllocaldb stop "test"
sqllocaldb delete "test"

#>