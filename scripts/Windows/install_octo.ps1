# https://octopus.com/downloads

Write-Host "Installing octo.exe cli 2.11.0..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Octopus'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:TEMP\OctopusTools.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/OctopusDeploy/cli/releases/download/v2.11.0/octopus_2.11.0_windows_amd64.zip', $zipPath)
7z x $zipPath -aoa -o"$destPath"
Remove-Item $zipPath

Add-Path $destPath
Add-SessionPath $destPath

cmd /c octo --version

Write-Host "Installed Octopus tools" -ForegroundColor Green