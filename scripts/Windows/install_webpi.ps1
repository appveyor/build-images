Write-Host "Installing Web PI"
Write-Host "================="

$webPIFolder = "$env:ProgramFiles\Microsoft\Web Platform Installer"
if([IO.File]::Exists("$webPIFolder\webpicmd.exe")) {
    Add-SessionPath $webPIFolder
    Write-Host "Web PI is already installed" -ForegroundColor Green
    return
}

# http://www.iis.net/learn/install/web-platform-installer/web-platform-installer-direct-downloads
$msiPath = "$env:TEMP\WebPlatformInstaller_amd64_en-US.msi"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?LinkId=287166', $msiPath)

cmd /c start /wait msiexec /i "$msiPath" /q
del $msiPath
Add-SessionPath $webPIFolder

Write-Host "Web PI installed"