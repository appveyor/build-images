Write-Host "Installing SilverLight 4 SDK..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\silverlight_sdk.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/F/2/C/F2CFFB78-03CF-4749-A6AE-EF60FB6FB14E/sdk/silverlight_sdk.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait "$exePath" /quiet /norestart RUNDEVENVSETUP=0
del $exePath

Write-Host "Installed" -ForegroundColor Green


Write-Host "Installing SilverLight 5 SDK..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:TEMP\silverlight_sdk.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/3/A/3/3A35179D-5C87-4D0A-91EB-BF5FEDC601A4/sdk/silverlight_sdk.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait "$exePath" /quiet /norestart RUNDEVENVSETUP=0
del $exePath

Write-Host "Installed" -ForegroundColor Green