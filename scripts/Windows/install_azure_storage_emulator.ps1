Write-Host "Installing Azure storage emulator 5.9..." -ForegroundColor Cyan
Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftAzureStorageEmulator.msi"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?LinkId=717179&clcid=0x409', $msiPath)
Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath
Write-Host "Installed Azure storage emulator" -ForegroundColor Green