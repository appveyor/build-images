Write-Host "Installing InnoSetup 6.0.2..." -ForegroundColor Cyan

$exePath = "$env:TEMP\innosetup-6.0.2.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('http://files.jrsoftware.org/is/6/innosetup-6.0.2.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
del $exePath

Write-Host "InnoSetup installed" -ForegroundColor Green