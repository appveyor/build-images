Write-Host "Stopping services..."

Set-Service 'MSSQL$SQL2016' -StartupType Manual
Set-Service 'MSSQLFDLauncher$SQL2016' -StartupType Manual
Set-Service 'SQLAgent$SQL2016' -StartupType Manual
Set-Service 'MSOLAP$SQL2016' -StartupType Manual
Set-Service 'SSASTELEMETRY$SQL2016' -StartupType Manual
Set-Service 'SQLTELEMETRY$SQL2016' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'ReportServer$SQL2016' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Stop-Service 'MSSQL$SQL2016'
Stop-Service 'MSSQLFDLauncher$SQL2016'
Stop-Service 'SQLAgent$SQL2016'
Stop-Service 'MSOLAP$SQL2016'
Stop-Service 'SSASTELEMETRY$SQL2016'
Stop-Service 'SQLTELEMETRY$SQL2016'
Stop-Service 'SQLBrowser'
Stop-Service 'ReportServer$SQL2016'
Stop-Service 'SQLWriter'

Write-Host "SQL Server 2016 installed" -ForegroundColor Green

# Install manually SQL Server 2016 Developer

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'sql2016'
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

<#

net start MSSQL$SQL2016

sqlcmd -S (local)\SQL2016 -U sa -P Password12! -Q "SELECT name from sys.databases"
net stop MSSQL$SQL2016

sqllocaldb create "test" 13.0 -s
sqllocaldb stop "test"
sqllocaldb delete "test"

#>