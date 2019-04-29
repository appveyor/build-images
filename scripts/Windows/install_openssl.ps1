function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
        | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
        | Where-Object { $_.DisplayName -and $_.DisplayName.Contains($productName) } `
        | Select UninstallString).UninstallString
}

function UninstallOpenSSL($productName) {
    $uninstaller = GetUninstallString $productName
    if($uninstaller) {
        Write-Host "Uninstalling $productName..." -NoNewline
        "$uninstaller /silent" | out-file "$env:temp\uninstall.cmd" -Encoding ASCII
        & "$env:temp\uninstall.cmd"
        del "$env:temp\uninstall.cmd"
        Write-Host "OK"
    }
}

UninstallOpenSSL "OpenSSL 1.0.2L (32-bit)"
UninstallOpenSSL "OpenSSL 1.0.2L (64-bit)"
UninstallOpenSSL "OpenSSL 1.0.2p (32-bit)"
UninstallOpenSSL "OpenSSL 1.0.2p (64-bit)"
UninstallOpenSSL "OpenSSL 1.1.0i (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.0i (64-bit)"
UninstallOpenSSL "OpenSSL 1.1.1 (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.1 (64-bit)"

Remove-Item C:\OpenSSL-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win64 -Recurse -Force -ErrorAction SilentlyContinue



Write-Host "Installing OpenSSL 1.1.0 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_1_0j.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win32OpenSSL-1_1_0j.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v11-Win32-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v11-Win32-temp -Destination C:\OpenSSL-v11-Win32 -Recurse




Write-Host "Installing OpenSSL 1.1.0 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_1_0j.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win64OpenSSL-1_1_0j.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v11-Win64-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v11-Win64-temp -Destination C:\OpenSSL-v11-Win64 -Recurse


UninstallOpenSSL "OpenSSL 1.1.0j (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.0j (64-bit)"




Write-Host "Installing OpenSSL 1.1.1 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_1_1b.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win32OpenSSL-1_1_1b.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v111-Win32-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v111-Win32-temp -Destination C:\OpenSSL-v111-Win32 -Recurse




Write-Host "Installing OpenSSL 1.1.1 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_1_1b.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win64OpenSSL-1_1_1b.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v111-Win64-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v111-Win64-temp -Destination C:\OpenSSL-v111-Win64 -Recurse


UninstallOpenSSL "OpenSSL 1.1.1b (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.1b (64-bit)"



Write-Host "Installing OpenSSL 1.0.x 32-bit ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_0_2r.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win32OpenSSL-1_0_2r.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
del $exePath

Write-Host "Installed" -ForegroundColor Green




Write-Host "Installing OpenSSL 1.0.x 64-bit ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_0_2r.exe"
(New-Object Net.WebClient).DownloadFile('https://slproweb.com/download/Win64OpenSSL-1_0_2r.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
del $exePath

Write-Host "Installed" -ForegroundColor Green
