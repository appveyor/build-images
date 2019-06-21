$110Letter = "k"
$111Letter = "c"
$102Letter = "s"

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
        $uninstaller | % {
        Write-Host "Uninstalling $productName..." -NoNewline
        "$_ /silent" | out-file "$env:temp\uninstall.cmd" -Encoding ASCII
        & "$env:temp\uninstall.cmd"
        del "$env:temp\uninstall.cmd"
        Write-Host "OK"
        }
    }
}

UninstallOpenSSL "OpenSSL 1.0.2"
UninstallOpenSSL "OpenSSL 1.1.0"
UninstallOpenSSL "OpenSSL 1.1.1"

Remove-Item C:\OpenSSL-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win64 -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installing OpenSSL 1.1.0$110Letter 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_1_0$110Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-1_1_0$110Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v11-Win32-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v11-Win32-temp -Destination C:\OpenSSL-v11-Win32 -Recurse

Write-Host "Installing OpenSSL 1.1.0$110Letter 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_1_0$110Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-1_1_0$110Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v11-Win64-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v11-Win64-temp -Destination C:\OpenSSL-v11-Win64 -Recurse

UninstallOpenSSL "OpenSSL 1.1.0$110Letter (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.0$110Letter (64-bit)"

Write-Host "Installing OpenSSL 1.1.1$111Letter 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_1_1$111Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-1_1_1$111Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v111-Win32-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v111-Win32-temp -Destination C:\OpenSSL-v111-Win32 -Recurse

Write-Host "Installing OpenSSL 1.1.1$111Letter 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_1_1$111Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-1_1_1$111Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v111-Win64-temp
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v111-Win64-temp -Destination C:\OpenSSL-v111-Win64 -Recurse

UninstallOpenSSL "OpenSSL 1.1.1$111Letter (32-bit)"
UninstallOpenSSL "OpenSSL 1.1.1$111Letter (64-bit)"

Write-Host "Installing OpenSSL 1.0.2$102Letter 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_0_2$102Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-1_0_2$102Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
del $exePath
Write-Host "Installed" -ForegroundColor Green

Write-Host "Installing OpenSSL 1.0.2$102Letter 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_0_2$102Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-1_0_2$102Letter.exe", $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
del $exePath
Write-Host "Installed" -ForegroundColor Green