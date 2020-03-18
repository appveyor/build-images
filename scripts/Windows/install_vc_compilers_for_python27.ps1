Write-Host "Installing Visual C++ Compiler for Python 2.7..." -ForegroundColor Cyan
$msiPath = "$env:TEMP\VCForPython27.msi"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
del $msiPath

Write-Host "Visual C++ Compiler for Python 2.7 installed" -ForegroundColor Green