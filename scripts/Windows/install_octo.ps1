# https://octopus.com/downloads

Write-Host "Installing octo.exe cli 2.11.0..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Octopus'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$oldZipPath = "$env:TEMP\OctopusTools.zip"
$zipPath = "$env:TEMP\OctoCli.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/OctopusDeploy/cli/releases/download/v2.11.0/octopus_2.11.0_windows_amd64.zip', $zipPath)
(New-Object Net.WebClient).DownloadFile('https://download.octopusdeploy.com/octopus-tools/6.17.0/OctopusTools.6.17.0.zip', $oldZipPath)
7z x $oldZipPath -aoa -o"$destPath"
7z x $zipPath -aoa -o"$destPath"
gci $destPath -r | select -exp FullName
Remove-Item $zipPath

Add-Path $destPath
Add-SessionPath $destPath

cmd /c octo --version
cmd /c octopus --version

Write-Host "Installed Octopus tools" -ForegroundColor Green