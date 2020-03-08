Write-Host "Installing PowerShell Core"
Write-Host "=========================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$msiPath = "$env:TEMP\PowerShell-Core.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/PowerShell-6.2.3-win-x64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet REGISTER_MANIFEST=1
Remove-Item $msiPath
Add-SessionPath "$env:ProgramFiles\PowerShell\6"

# Make AppVeyor cmdlets visible in external PowerShell Core sessions
$appveyorPath = "$env:ProgramFiles\AppVeyor\BuildAgent"
if (Test-Path $appveyorPath) {
    $pwshProfilePath = "$env:USERPROFILE\Documents\PowerShell"
    if (-not (Test-Path $pwshProfilePath)) {
        New-Item $pwshProfilePath -ItemType Directory -Force | Out-Null
    }
    
    $pwshProfileFilename = "$pwshProfilePath\Microsoft.PowerShell_profile.ps1"
    Add-Content $pwshProfileFilename "`nImport-Module '$appveyorPath\dotnetcore\AppVeyor.BuildAgent.PowerShell.dll'"
}

# Check version
pwsh --version

Write-Host "PowerShell Core Installed"