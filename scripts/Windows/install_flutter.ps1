. "$PSScriptRoot\common.ps1"

$version = '3.13.2'

Write-Host "Installing Flutter SDK $version"
Write-Host "====================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$zipPath = "$env:TEMP\flutter_windows_$version-stable.zip"

Write-Host "Downloading Flutter SDK..."
(New-Object Net.WebClient).DownloadFile("https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$version-stable.zip", $zipPath)

Write-Host "Unpacking Flutter SDK..."
7z x $zipPath -o"$env:SystemDrive\" | Out-Null

Add-SessionPath "$env:SystemDrive\flutter\bin"
Add-Path "$env:SystemDrive\flutter\bin"

Start-ProcessWithOutput "flutter upgrade"
Start-ProcessWithOutput "flutter doctor -v"

Write-Host "Flutter SDK installed"