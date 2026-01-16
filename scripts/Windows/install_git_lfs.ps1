Write-Host "Installing Git LFS" -ForegroundColor Cyan
Write-Host "=================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# delete existing Git LFS
del "${env:ProgramFiles}\Git\mingw64\bin\git-lfs.exe" -ErrorAction SilentlyContinue

$exePath = "$env:TEMP\git-lfs-windows.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/git-lfs/git-lfs/releases/download/v3.7.1/git-lfs-windows-v3.7.1.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

Add-Path "$env:ProgramFiles\Git LFS"
Add-SessionPath "$env:ProgramFiles\Git LFS"

git lfs install --force
git lfs version

Write-Host "Git LFS installed"
