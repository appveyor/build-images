$version = '7.1.3'

Write-Host "Installing PowerShell Core $version"
Write-Host "=========================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$msiPath = "$env:TEMP\PowerShell-Core.msi"
(New-Object Net.WebClient).DownloadFile("https://github.com/PowerShell/PowerShell/releases/download/v$version/PowerShell-$version-win-x64.msi", $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet REGISTER_MANIFEST=1
Remove-Item $msiPath
Add-SessionPath "$env:ProgramFiles\PowerShell\7"

# Make AppVeyor cmdlets visible in external PowerShell Core sessions
$appveyorPath = "$env:ProgramFiles\AppVeyor\BuildAgent"
if (Test-Path $appveyorPath) {
    $pwshProfilePath = "$env:USERPROFILE\Documents\PowerShell"
    if (-not (Test-Path $pwshProfilePath)) {
        New-Item $pwshProfilePath -ItemType Directory -Force | Out-Null
    }
    
    $pwshProfileFilename = "$pwshProfilePath\Microsoft.PowerShell_profile.ps1"

    if (-not (Test-Path $pwshProfileFilename) -or (Get-Content $pwshProfileFilename | Where-Object { $_.Contains("AppVeyor.BuildAgent.PowerShell.dll") }).Count -eq 0) {
        Write-Host "Updating $pwshProfileFilename with AppVeyor PS Modules"
        Add-Content $pwshProfileFilename "`nImport-Module '$appveyorPath\dotnetcore\AppVeyor.BuildAgent.PowerShell.dll'"
    } else {
        Write-Host "Import of AppVeyor Modules already exists in $pwshProfileFilename"
    }
}

# Check version
pwsh --version

Write-Host "PowerShell Core Installed"