Write-Host "Installing Docker Desktop 4.49.0"

Write-Host "Downloading..."
$exePath = "$env:TEMP\Docker-Desktop-Installer.exe"
(New-Object Net.WebClient).DownloadFile('https://desktop.docker.com/win/main/amd64/208700/Docker%20Desktop%20Installer.exe', $exePath)


Write-Host "Installing..."
cmd /c start /w $exePath install --quiet --accept-license --backend=wsl-2 --always-run-service
Remove-Item $exePath

Write-Host "Docker Desktop installed" -ForegroundColor Green
