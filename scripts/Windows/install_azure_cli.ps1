Write-Host "Installing Azure CLI..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$($env:USERPROFILE)\installazurecliwindows.msi"
(New-Object Net.WebClient).DownloadFile('https://aka.ms/installazurecliwindows', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath

Write-Host "Installed Azure CLI" -ForegroundColor Green