Write-Host "Installing Google Cloud SDK..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\GoogleCloudSDKInstaller.exe"
(New-Object Net.WebClient).DownloadFile('https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S /allusers
del $exePath

Write-Host "Installed Google Cloud SDK" -ForegroundColor Green