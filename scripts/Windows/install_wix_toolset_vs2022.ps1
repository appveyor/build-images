Write-Host "Installing WiX Toolset Visual Studio 2022..." -ForegroundColor Cyan
Write-Host "Downloading..."
$vsixPath = "$env:TEMP\Votive2022.vsix"
(New-Object Net.WebClient).DownloadFile('https://github.com/wixtoolset/VisualStudioExtension/releases/download/v1.0.0.12/Votive2022.vsix', $vsixPath)
Write-Host "Installing..."

$vsPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Preview"
}

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait
Remove-Item $vsixPath -Force -ErrorAction Ignore

Write-Host "Installed" -ForegroundColor Green