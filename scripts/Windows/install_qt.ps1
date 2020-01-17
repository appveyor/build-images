Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

Write-Host "Downloading Qt Installer..."
$exePath = "$env:TEMP\qt-unified-windows-x86-online.exe"
(New-Object Net.WebClient).DownloadFile('http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe', $exePath)

$qsPath = "$PSScriptRoot\install_qt.qs"
if (-not (Test-Path $qsPath)) {
    $qsPath = "$env:TEMP\install_qt.qs"
}

Write-Host "Installing..."
cmd /c "$exePath" --verbose --script "$qsPath"
Remove-Item $exePath

# compressing folder
Write-Host "Compacting C:\Qt..." -NoNewline
compact /c /i /s:C:\Qt | Out-Null
Write-Host "OK" -ForegroundColor Green

# set aliases
cmd /c mklink /J C:\Qt\latest C:\Qt\5.14.0
cmd /c mklink /J C:\Qt\5.14 C:\Qt\5.14.0
cmd /c mklink /J C:\Qt\5.13 C:\Qt\5.13.2
cmd /c mklink /J C:\Qt\5.12 C:\Qt\5.12.6
cmd /c mklink /J C:\Qt\5.9 C:\Qt\5.9.9

Write-Host "Qt 5.x installed" -ForegroundColor Green
