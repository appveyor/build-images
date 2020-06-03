Write-Host "Installing WDK 2004 (10.0.19041.0)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\wdksetup.exe"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?linkid=2128854', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /quiet
Remove-Item $exePath -Force -ErrorAction Ignore
Write-Host "OK"

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview"
}

if (-not (Test-Path $vsPath)) {
  return
}

Write-Host "Installing Visual Studio 2019 WDK extension..."

Start-Process "$vsPath\Common7\IDE\VSIXInstaller.exe" "/q /a `"${env:ProgramFiles(x86)}\Windows Kits\10\Vsix\VS2019\WDK.vsix`"" -Wait

Write-Host "Installed" -ForegroundColor Green