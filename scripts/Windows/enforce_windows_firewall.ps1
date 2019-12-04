Write-Host "Disabling all inbound Windows Firewall Rules"

Get-NetFirewallRule | Where-Object { $_.DisplayGroup -ne 'Windows Remote Management' } | Disable-NetFirewallRule