Write-Host "Installing InnoSetup 5.5.9..." -ForegroundColor Cyan

$exePath = "$env:TEMP\innosetup-5.5.9-unicode.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('http://www.jrsoftware.org/download.php/is-unicode.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-
del $exePath

Write-Host "InnoSetup installed" -ForegroundColor Green