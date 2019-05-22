Write-Host "Installing WDK 1903 (10.0.18362.0)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\wdksetup.exe"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?linkid=2083338', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /features + /quiet

Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green