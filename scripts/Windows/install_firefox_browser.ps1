. "$PSScriptRoot\common.ps1"

$firefoxVersion = "126.0"

Write-Host "Installing FireFox $firefoxVersion..." -ForegroundColor Cyan

$arch = 'win64'
if (test-path "${env:ProgramFiles(x86)}\Mozilla Firefox") {
    Write-Host "32-bit version on Firefox is already installed" -ForegroundColor Yellow
    Write-Host "Upgrading to the latest version of 32-bit..." -ForegroundColor Yellow
    $arch = 'win'
}

Write-Host "Downloading..."
$exePath = "$env:TEMP\firefox-installer.exe"
(New-Object Net.WebClient).DownloadFile("https://download.mozilla.org/?product=firefox-$firefoxVersion-ssl&os=$arch&lang=en-US", $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath -ms
Remove-Item $exePath

GetProductVersion "Firefox"

Write-Host "Installed FireFox $firefoxVersion" -ForegroundColor Green