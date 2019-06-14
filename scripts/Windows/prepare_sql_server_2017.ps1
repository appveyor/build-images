Write-Host "Preparing SQL Server 2017..."
Write-Host "Stopping services..."

Set-Service 'MSSQL$SQL2017' -StartupType Manual
Set-Service 'MSSQLFDLauncher$SQL2017' -StartupType Manual
Set-Service 'SQLAgent$SQL2017' -StartupType Manual
Set-Service 'MSOLAP$SQL2017' -StartupType Manual -ErrorAction Ignore
Set-Service 'SSASTELEMETRY$SQL2017' -StartupType Manual -ErrorAction Ignore
Set-Service 'SQLTELEMETRY$SQL2017' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'SQLServerReportingServices' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Stop-Service 'MSSQL$SQL2017'
Stop-Service 'MSSQLFDLauncher$SQL2017'
Stop-Service 'SQLAgent$SQL2017'
Stop-Service 'MSOLAP$SQL2017' -ErrorAction Ignore
Stop-Service 'SSASTELEMETRY$SQL2017' -ErrorAction Ignore
Stop-Service 'SQLTELEMETRY$SQL2017'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLServerReportingServices'
Stop-Service 'SQLWriter'

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'SQL2017'
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