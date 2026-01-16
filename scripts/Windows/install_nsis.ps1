Write-Host "Installing NSIS 3.10 ..." -ForegroundColor Cyan
$exePath = "$($env:TEMP)\nsis-3.10-setup.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/nsis-3.10-setup.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S
del $exePath
Write-Host "Installed" -ForegroundColor Green

Remove-Item "$env:USERPROFILE\Desktop\NSIS.lnk" -Force -ErrorAction Ignore

Add-Path "${env:ProgramFiles(x86)}\NSIS"
Add-SessionPath "${env:ProgramFiles(x86)}\NSIS"
