Write-Host "Installing Windows SDK 8.1..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\sdksetup.exe"
(New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/B/0/C/B0C80BA3-8AD6-4958-810B-6882485230B5/standalonesdk/sdksetup.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /Quiet /NoRestart
Start-Sleep -s 15
Remove-Item $exePath -ErrorAction SilentlyContinue -Verbose

Write-Host "Installed Windows SDK 8.1" -ForegroundColor Green