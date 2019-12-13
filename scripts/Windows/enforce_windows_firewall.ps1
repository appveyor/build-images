Write-Host "Disabling all inbound Windows Firewall Rules except WinRM (5985, 5986 ports)"

Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -ne 5985 -and $_.LocalPort -ne 5986 } | `
    Get-NetFirewallRule | Where-Object { $_.Direction -eq 'Inbound' } | `
    Disable-NetFirewallRule