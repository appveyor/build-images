Write-Host "Installing NSIS 3.06.01 ..." -ForegroundColor Cyan
$exePath = "$($env:TEMP)\nsis-3.04-setup.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://pilotfiber.dl.sourceforge.net/project/nsis/NSIS%203/3.06.1/nsis-3.06.1-setup.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /S
del $exePath
Write-Host "Installed" -ForegroundColor Green

Remove-Item "$env:USERPROFILE\Desktop\NSIS.lnk" -Force -ErrorAction Ignore

Add-Path "${env:ProgramFiles(x86)}\NSIS"
Add-SessionPath "${env:ProgramFiles(x86)}\NSIS"
