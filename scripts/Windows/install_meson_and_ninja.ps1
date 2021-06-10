Write-Host "Installing Meson and Ninja..." -ForegroundColor Cyan

$mesonUrl = 'https://github.com/mesonbuild/meson/releases/download/0.58.1/meson-0.58.1-64.msi'
$ninjaUrl = 'https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip'

Write-Host "Downloading..."
$msiPath = "$env:TEMP\meson.msi"
(New-Object Net.WebClient).DownloadFile($mesonUrl, $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet
Remove-Item $msiPath

Write-Host "Downloading Ninja..."
$zipPath = "$env:TEMP\ninja-win.zip"
(New-Object Net.WebClient).DownloadFile($ninjaUrl, $zipPath)

Write-Host "Unpacking Ninja..."
7z x $zipPath -aoa -o"`"$env:ProgramFiles\Meson`"" | Out-Null
Remove-Item $zipPath

Write-Host "Ninja version:"
& "$env:ProgramFiles\Meson\ninja.exe" --version

Write-Host "Meson version:"
& "$env:ProgramFiles\Meson\meson.exe" --version

Write-Host "Installed Meson and Ninja" -ForegroundColor Green
