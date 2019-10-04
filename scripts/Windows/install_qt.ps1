Write-Host "Installing Qt 5.x ..." -ForegroundColor Cyan

Write-Host "Downloading Qt Installer..."
$exePath = "$env:TEMP\qt-unified-windows-x86-online.exe"
(New-Object Net.WebClient).DownloadFile('http://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe', $exePath)

Write-Host "Installing..."
cmd /c "$exePath" --verbose --script "$PSScriptRoot\qt-installer-windows.qs"
Remove-Item $exePath

Write-Host "Qt 5.x installed" -ForegroundColor Green
