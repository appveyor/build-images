Write-Host "Installing FireFox..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\firefox-installer.exe"
(New-Object Net.WebClient).DownloadFile('https://download.mozilla.org/?product=firefox-72.0-ssl&os=win64&lang=en-US', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath -ms
del $exePath

Write-Host "Installed FireFox" -ForegroundColor Green