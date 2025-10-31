Write-Host "Installing Windows 11 SDK (10.0.26100)..." -ForegroundColor Cyan

Write-Host "Downloading..."
$isoPath = "$env:TEMP\sdksetup.iso"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/3a857edb-459d-4fbb-88dc-5153f6183142/26100.4948.250812-1640.ge_release_svc_im_WindowsSDK.iso', $isoPath)

$extractPath = "$env:TEMP\sdksetup26100"
Write-Host "Extracting..."
7z x $isoPath -aoa -o"$extractPath" | Out-Null

Write-Host "Installing..."
cmd /c start /wait $extractPath\WinSDKSetup.exe /features + /quiet

Write-Host "Deleting temporary files..."
Remove-Item $isoPath -Force -ErrorAction Ignore
Remove-Item $extractPath -Recurse -Force -ErrorAction Ignore

dir "C:\Program Files (x86)\Windows Kits\10\bin"

Write-Host "Installed" -ForegroundColor Green