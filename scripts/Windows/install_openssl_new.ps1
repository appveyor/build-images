
function GetUninstallString($productName) {
    $x64items = @(Get-ChildItem "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
    ($x64items + @(Get-ChildItem "HKLM:SOFTWARE\wow6432node\Microsoft\Windows\CurrentVersion\Uninstall") `
    | ForEach-object { Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_ } `
    | Where-Object { $_.DisplayName -and $_.DisplayName.Contains($productName) } `
    | Select UninstallString).UninstallString
}

function UninstallOpenSSL($productName) {
    $uninstaller = GetUninstallString $productName
    if ($uninstaller) {
        $uninstaller | % {
            Write-Host "Uninstalling $productName..." -NoNewline
            "$_ /silent" | out-file "$env:temp\uninstall.cmd" -Encoding ASCII
            & "$env:temp\uninstall.cmd"
            del "$env:temp\uninstall.cmd"
            Write-Host "OK"
        }
    }
}


Write-Host "Installing OpenSSL 3.4.3 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_4_3.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_4_3.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v34-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v34-Win32-temp -Destination C:\OpenSSL-v34-Win32 -Recurse

Write-Host "Installing OpenSSL 3.4.3 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_4_3.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_4_3.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v34-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v34-Win64-temp -Destination C:\OpenSSL-v34-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.4.3 (32-bit)"
UninstallOpenSSL "OpenSSL 3.4.3 (64-bit)"

Write-Host "Installing OpenSSL 3.5.4 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_5_4.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_5_4.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v35-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v35-Win32-temp -Destination C:\OpenSSL-v35-Win32 -Recurse

Write-Host "Installing OpenSSL 3.5.4 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_5_4.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_5_4.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v35-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v35-Win64-temp -Destination C:\OpenSSL-v35-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.5.4 (32-bit)"
UninstallOpenSSL "OpenSSL 3.5.4 (64-bit)"

Write-Host "Installing OpenSSL 3.6.0 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_6_0.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_6_0.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v36-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v36-Win32-temp -Destination C:\OpenSSL-v36-Win32 -Recurse

Write-Host "Installing OpenSSL 3.6.0 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_6_0.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_6_0.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v36-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v36-Win64-temp -Destination C:\OpenSSL-v36-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.6.0 (32-bit)"
UninstallOpenSSL "OpenSSL 3.6.0 (64-bit)"