Write-Host "Installing WiX 3.11 ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\wix311.exe"
(New-Object Net.WebClient).DownloadFile('http://wixtoolset.org/downloads/v3.11.0.1528/wix311.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait "$exePath" /q
Remove-Item $exePath

Write-Host "WiX 3.11 installed" -ForegroundColor Green