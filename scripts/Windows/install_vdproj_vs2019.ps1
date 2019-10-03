Write-Host "Installing Visual Studio Installer Projects 2019..." -ForegroundColor Cyan
Write-Host "Downloading..."
$vsixPath = "$($env:TEMP)\InstallerProjects.vsix"
(New-Object Net.WebClient).DownloadFile('https://visualstudioclient.gallerycdn.vsassets.io/extensions/visualstudioclient/microsoftvisualstudio2017installerprojects/0.9.3/1557425218768/InstallerProjects.vsix', $vsixPath)
Write-Host "Installing..."
Start-Process "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait
Write-Host "Installed" -ForegroundColor Green
Remove-Item $vsixPath -Force -ErrorAction Ignore