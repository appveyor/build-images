Write-Host "Installing Notepad++ ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\npp.7.3.1.Installer.exe"
(New-Object Net.WebClient).DownloadFile('https://notepad-plus-plus.org/repository/7.x/7.3.1/npp.7.3.1.Installer.exe', $exePath)

Write-Host "Installing..."
cmd /c start "$exePath" /S
del $exePath

Write-Host "Notepad++ installed" -ForegroundColor Green