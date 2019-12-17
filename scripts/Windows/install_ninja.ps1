Write-Host "Installing Ninja..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Ninja'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:TEMP\ninja-win.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip', $zipPath)
7z x $zipPath -aoa -o"$destPath"
del $zipPath

Add-Path $destPath
Add-SessionPath $destPath

cmd /c ninja --version

Write-Host "Installed Ninja" -ForegroundColor Green