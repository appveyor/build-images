Write-Host "Installing DocumentDB Emulator ..." -ForegroundColor Cyan
$msiPath = "$($env:TEMP)\DocumentDB.Emulator.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://aka.ms/documentdb-emulator', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet /qn
del $msiPath

dir "${env:ProgramFiles}\DocumentDB Emulator\"

Write-Host "DocumentDB Emulator installed" -ForegroundColor Green