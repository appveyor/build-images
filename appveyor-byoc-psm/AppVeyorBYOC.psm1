# original idea from here: https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1

# Import all .ps1 as cmdlets

$cmdlets  = @( Get-ChildItem -Path $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in $cmdlets)
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import cmdlet $($import.fullname): $_"
    }
}

# .ps1 should have the same name as containing cmdlet
Export-ModuleMember -Function $cmdlets.Basename