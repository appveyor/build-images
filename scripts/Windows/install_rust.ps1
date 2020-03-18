Write-Host "Installing Rust..." -ForegroundColor Cyan
$exePath = "$env:TEMP\rustup-init.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath -y
Remove-Item $exePath

Add-SessionPath "$env:USERPROFILE\.cargo\bin"

cargo --version
rustup --version
rustc --version

Write-Host "Rust installed" -ForegroundColor Green