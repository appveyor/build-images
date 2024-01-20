Write-Host "Installing Docker Desktop 4.25.1"

Write-Host "Downloading..."
$exePath = "$env:TEMP\Docker-Desktop-Installer.exe"
(New-Object Net.WebClient).DownloadFile('https://desktop.docker.com/win/main/amd64/128006/Docker%20Desktop%20Installer.exe', $exePath)

Write-Host "Installing..."
cmd /c start /w $exePath install --quiet --accept-license --backend=wsl-2 --always-run-service
Remove-Item $exePath

Write-Host "Docker Desktop installed" -ForegroundColor Green

#Write-Host "adding to docker-users group..."
#net localgroup docker-users "appveyor" /add