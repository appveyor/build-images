Write-Host "Installing InnoSetup 6.7.3..." -ForegroundColor Cyan

$exePath = "$env:TEMP\innosetup-6.7.3.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
Remove-Item $exePath

Write-Host "InnoSetup installed" -ForegroundColor Green
