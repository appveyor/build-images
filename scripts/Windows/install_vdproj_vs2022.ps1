Write-Host "Installing Visual Studio Installer Projects 2022..." -ForegroundColor Cyan
Write-Host "Downloading..."
$vsixPath = "$($env:TEMP)\InstallerProjects.vsix"
(New-Object Net.WebClient).DownloadFile('https://visualstudioclient.gallerycdn.vsassets.io/extensions/visualstudioclient/microsoftvisualstudio2022installerprojects/0.1.0/1631880472071/InstallerProjects.vsix', $vsixPath)
Write-Host "Installing..."

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Preview"
}

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait
Remove-Item $vsixPath -Force -ErrorAction Ignore

# Enable VDPROJ support in the Registry
Push-Location "$vsPath\Common7\IDE\CommonExtensions\Microsoft\VSI\DisableOutOfProcBuild"
& .\DisableOutOfProcBuild.exe
Pop-Location

Write-Host "Installed" -ForegroundColor Green