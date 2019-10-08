Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

Write-Host "Downloading Qt Installer..."
$exePath = "$env:TEMP\qt-unified-windows-x86-online.exe"
(New-Object Net.WebClient).DownloadFile('http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe', $exePath)

$qsPath = "$PSScriptRoot\qt-installer-windows.qs"
if (-not (Test-Path $qsPath)) {
    $qsPath = "$env:TEMP\qt-installer-windows.qs"
}

Write-Host "Installing..."
cmd /c "$exePath" --script "$qsPath"
Remove-Item $exePath

# set aliases
cmd /c mklink /J C:\Qt\latest C:\Qt\5.13.1
cmd /c mklink /J C:\Qt\5.13 C:\Qt\5.13.1
cmd /c mklink /J C:\Qt\5.12 C:\Qt\5.12.5
cmd /c mklink /J C:\Qt\5.9 C:\Qt\5.9.8

Write-Host "Qt 5.x installed" -ForegroundColor Green
