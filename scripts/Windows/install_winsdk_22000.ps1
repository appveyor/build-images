Write-Host "Installing Windows 11 SDK (10.0.22000.1)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$isoPath = "$env:TEMP\sdksetup.iso"
(New-Object Net.WebClient).DownloadFile('https://go.microsoft.com/fwlink/?linkid=2173746', $isoPath)

$extractPath = "$env:TEMP\sdksetup22000"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\WinSDKSetup.exe /features + /quiet

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

dir "C:\Program Files (x86)\Windows Kits\10\bin"

Write-Host "Installed" -ForegroundColor Green