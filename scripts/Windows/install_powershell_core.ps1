Write-Host "Installing PowerShell Core"
Write-Host "=========================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$msiPath = "$env:TEMP\PowerShell-Core.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/PowerShell-6.2.0-win-x64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
del $msiPath
Add-SessionPath "$env:ProgramFiles\PowerShell\6"

pwsh --version

Write-Host "PowerShell Core Installed"