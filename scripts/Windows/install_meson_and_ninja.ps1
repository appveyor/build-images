Write-Host "Installing Meson and Ninja..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\meson.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/mesonbuild/meson/releases/download/0.52.1/meson-0.52.1-64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet
del $msiPath

Write-Host "Ninja version:"
& "$env:ProgramFiles\Meson\ninja.EXE" --version

Write-Host "Meson version:"
& "$env:ProgramFiles\Meson\meson.exe" --version

Write-Host "Installed Meson and Ninja" -ForegroundColor Green