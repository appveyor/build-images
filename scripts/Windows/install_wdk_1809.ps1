Write-Host "Installing WDK 1809 (10.0.17763.0)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\wdksetup.exe"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?linkid=2026156', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /features + /quiet

Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green