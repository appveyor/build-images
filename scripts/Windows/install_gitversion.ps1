Write-Host "Installing GitVersion..." -ForegroundColor Cyan
$gvPath = "$env:SYSTEMDRIVE\Tools\GitVersion"
if (Test-Path $gvPath) {
    Remove-Item $gvPath -Recurse -Force
}

Write-Host "Downloading GitVersion..."
$zipPath = "$env:TEMP\gitversion.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/GitTools/GitVersion/releases/download/5.10.3/gitversion-win-x64-5.10.3.zip', $zipPath)

Write-Host "Unpacking GitVersion..."
7z x $zipPath -aoa -o"$gvPath" | Out-Null
Remove-Item $zipPath

Add-Path $gvPath
Write-Host "GitVersion installed" -ForegroundColor Green