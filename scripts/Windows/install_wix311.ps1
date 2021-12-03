Write-Host "Installing WiX 3.11.1 ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\wix311.exe"
(New-Object Net.WebClient).DownloadFile('https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait "$exePath" /q
Remove-Item $exePath

Write-Host "WiX 3.11.1 installed" -ForegroundColor Green
