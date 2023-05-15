Write-Host "Preparing SQL Server 2019..."

Write-Host "Stopping services..."

Stop-Service 'MSSQL$SQL2022'
Stop-Service 'MSSQLFDLauncher$SQL2022'
Stop-Service 'SQLAgent$SQL2022'
Stop-Service 'MSOLAP$SQL2022' -ErrorAction Ignore
Stop-Service 'SSASTELEMETRY$SQL2022' -ErrorAction Ignore
Stop-Service 'SQLTELEMETRY$SQL2022'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLServerReportingServices'
Stop-Service 'SQLWriter'

Write-Host "Changing services startup mode..."

Set-Service 'MSSQL$SQL2022' -StartupType Manual
Set-Service 'MSSQLFDLauncher$SQL2022' -StartupType Manual
Set-Service 'SQLAgent$SQL2022' -StartupType Manual
Set-Service 'MSOLAP$SQL2022' -StartupType Manual -ErrorAction Ignore
Set-Service 'SSASTELEMETRY$SQL2022' -StartupType Manual -ErrorAction Ignore
Set-Service 'SQLTELEMETRY$SQL2022' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'SQLServerReportingServices' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Write-Host "Updating SQL Server TCP/IP configuration..."

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'SQL2022'
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

Write-Host "SQL Server 2022 configured" -ForegroundColor Green