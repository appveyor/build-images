# C:\Program Files (x86)\NSIS
Write-Host "Installing NSIS 3.04 ..." -ForegroundColor Cyan
$exePath = "$($env:TEMP)\nsis-3.04-setup.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://downloads.sourceforge.net/project/nsis/NSIS%203/3.04/nsis-3.04-setup.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S
del $exePath
Write-Host "Installed" -ForegroundColor Green

Remove-Item "$env:USERPROFILE\Desktop\NSIS.lnk" -Force -ErrorAction Ignore

Add-Path 'C:\Program Files (x86)\NSIS'
Add-SessionPath 'C:\Program Files (x86)\NSIS'
