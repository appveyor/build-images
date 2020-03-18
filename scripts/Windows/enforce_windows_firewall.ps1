Write-Host "Disabling all inbound Windows Firewall Rules"

Get-NetFirewallPortFilter | Get-NetFirewallRule | Where-Object { $_.Direction -eq 'Inbound' } | `
    Disable-NetFirewallRule