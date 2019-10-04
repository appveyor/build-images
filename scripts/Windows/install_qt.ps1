Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

Write-Host "Downloading Qt Installer..."
$exePath = "$env:TEMP\qt-unified-windows-x86-online.exe"
(New-Object Net.WebClient).DownloadFile('http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe', $exePath)

$qsPath = "$PSScriptRoot\qt-installer-windows.qs"
if (-not (Test-Path $qsPath)) {
    $qsPath = "$env:TEMP\qt-installer-windows.qs"
}

Write-Host "Installing..."
cmd /c "$exePath" --verbose --script "$qsPath"
Remove-Item $exePath

Write-Host "Qt 5.x installed" -ForegroundColor Green
