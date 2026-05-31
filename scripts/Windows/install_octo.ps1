# https://octopus.com/downloads

Write-Host "Installing octo.exe cli 2.20.1..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Octopus'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

#$oldZipPath = "$env:TEMP\OctopusTools.zip"
$msiPath = "$env:TEMP\OctoCli.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/OctopusDeploy/cli/releases/download/v2.20.1/octopus_2.20.1_windows_amd64.msi', $msiPath)
# (New-Object Net.WebClient).DownloadFile('https://download.octopusdeploy.com/octopus-tools/6.17.0/OctopusTools.6.17.0.zip', $oldZipPath)
#7z x $oldZipPath -aoa -o"$destPath"
7z x $msiPath -aoa -o"$destPath"
gci $destPath -r | select -exp FullName
Remove-Item $msiPath

Add-Path $destPath
Add-SessionPath $destPath

cmd /c octopus --version

Write-Host "Installed Octopus tools" -ForegroundColor Green
