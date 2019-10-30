Write-Host "Installing PowerShell Core"
Write-Host "=========================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading..."
$msiPath = "$env:TEMP\PowerShell-Core.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/PowerShell-6.2.3-win-x64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1
del $msiPath
Add-SessionPath "$env:ProgramFiles\PowerShell\6"

pwsh --version

Write-Host "PowerShell Core Installed"