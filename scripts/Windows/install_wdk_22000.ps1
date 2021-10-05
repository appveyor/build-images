Write-Host "Installing Windows 11 WDK (10.0.22000.1)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\wdksetup.exe"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?linkid=2166289', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /features + /quiet

Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green