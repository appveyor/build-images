Write-Host "Installing Yarn..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\yarn.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/yarnpkg/yarn/releases/download/v1.16.0/yarn-1.16.0.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet
del $msiPath

Add-Path "${env:ProgramFiles(x86)}\Yarn\bin"

Write-Host "Yarn installed" -ForegroundColor Green
