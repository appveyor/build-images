Write-Host "Installing InnoSetup 6.1.2..." -ForegroundColor Cyan

$exePath = "$env:TEMP\innosetup-6.1.2.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://files.jrsoftware.org/is/6/innosetup-6.1.2.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
Remove-Item $exePath

Write-Host "InnoSetup installed" -ForegroundColor Green