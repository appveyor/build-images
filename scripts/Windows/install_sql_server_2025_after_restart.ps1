Write-Host "Preparing SQL Server 2025..."

Write-Host "Stopping services..."

Stop-Service 'MSSQL$SQL2025'
Stop-Service 'MSSQLFDLauncher$SQL2025'
Stop-Service 'SQLAgent$SQL2025'
Stop-Service 'MSOLAP$SQL2025' -ErrorAction Ignore
Stop-Service 'SSASTELEMETRY$SQL2025' -ErrorAction Ignore
Stop-Service 'SQLTELEMETRY$SQL2025'
Stop-Service 'SQLBrowser'
Stop-Service 'SQLWriter'

Write-Host "Changing services startup mode..."

Set-Service 'MSSQL$SQL2025' -StartupType Manual
Set-Service 'MSSQLFDLauncher$SQL2025' -StartupType Manual
Set-Service 'SQLAgent$SQL2025' -StartupType Manual
Set-Service 'MSOLAP$SQL2025' -StartupType Manual -ErrorAction Ignore
Set-Service 'SSASTELEMETRY$SQL2025' -StartupType Manual -ErrorAction Ignore
Set-Service 'SQLTELEMETRY$SQL2025' -StartupType Manual
Set-Service 'SQLBrowser' -StartupType Manual
Set-Service 'SQLWriter' -StartupType Manual

Write-Host "Updating SQL Server TCP/IP configuration..."

Import-Module "sqlps" -DisableNameChecking -ErrorAction SilentlyContinue 3> $null
$instanceName = 'SQL2025'
$computerName = $env:COMPUTERNAME
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = New-Object ($smo + 'Wmi.ManagedComputer')

$uri = "ManagedComputer[@Name='$computerName']/ ServerInstance[@Name='$instanceName']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
ForEach ($ipAddress in $Tcp.IPAddresses)
{
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = "1433"
}
$Tcp.IsEnabled = $true
$Tcp.Alter()

Write-Host "Trying to start SQL Server service..."
Start-Service SQLBrowser
Start-Service "MSSQL`$$instanceName"

Write-Host "Stopping SQL Server service..."
Stop-Service "MSSQL`$$instanceName"
Stop-Service "MSSQLFDLauncher`$$instanceName" -ErrorAction SilentlyContinue
Stop-Service SQLBrowser

Write-Host "SQL Server 2025 configured" -ForegroundColor Green
