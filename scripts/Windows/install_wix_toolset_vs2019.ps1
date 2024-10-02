Write-Host "Installing WiX Toolset Visual Studio 2019..." -ForegroundColor Cyan
Write-Host "Downloading..."
$vsixPath = "$env:TEMP\Votive2019.vsix"
(New-Object Net.WebClient).DownloadFile('https://github.com/wixtoolset/VisualStudioExtension/releases/download/v1.0.0.22/Votive2019.vsix', $vsixPath)
Write-Host "Installing..."

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview"
}

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a $vsixPath" -Wait
Remove-Item $vsixPath -Force -ErrorAction Ignore

Write-Host "Installed" -ForegroundColor Green