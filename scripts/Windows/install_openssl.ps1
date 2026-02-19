$110Letter = "L"
$111Letter = "w"
$102Letter = "u"

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

UninstallOpenSSL "OpenSSL 1.0.2"
UninstallOpenSSL "OpenSSL 1.1.0"
UninstallOpenSSL "OpenSSL 1.1.1"

Remove-Item C:\OpenSSL-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v11-Win64 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win32 -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\OpenSSL-v111-Win64 -Recurse -Force -ErrorAction SilentlyContinue

# Write-Host "Installing OpenSSL 1.1.0$110Letter 32-bit ..." -ForegroundColor Cyan
# Write-Host "Downloading..."
# $zipPath = "$env:temp\OpenSSL-v110L-Win32.zip"
# (New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/misc/OpenSSL-v110L-Win32.zip", $zipPath)
# if (-not (Test-Path $zipPath)) { throw "Unable to find $zipPath" }
# Write-Host "Installing..."
# 7z x $zipPath -o"$env:SYSTEMDRIVE\" | Out-Null
# Remove-Item $zipPath
# Write-Host "Installed" -ForegroundColor Green


# Write-Host "Installing OpenSSL 1.1.0$110Letter 64-bit ..." -ForegroundColor Cyan
# Write-Host "Downloading..."
# $zipPath = "$env:temp\OpenSSL-v110L-Win64.zip"
# (New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/misc/OpenSSL-v110L-Win64.zip", $zipPath)
# if (-not (Test-Path $zipPath)) { throw "Unable to find $zipPath" }
# Write-Host "Installing..."
# 7z x $zipPath -o"$env:SYSTEMDRIVE\" | Out-Null
# Remove-Item $zipPath
# Write-Host "Installed" -ForegroundColor Green


Write-Host "Installing OpenSSL 1.1.1$111Letter 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_1_1$111Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-1_1_1$111Letter.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
# Move 32-bit OpenSSL directory
$openssl32 = (Get-ChildItem -Path ${env:ProgramFiles(x86)} -Directory -Filter "OpenSSL*")[0]
Move-Item -Path $openssl32.FullName -Destination "C:\$($openssl32.Name)" -Force
Write-Host "Moved 32-bit OpenSSL to C:\$($openssl32.Name)"

Write-Host "Installing OpenSSL 1.1.1$111Letter 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_1_1$111Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-1_1_1$111Letter.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
# Move 64-bit OpenSSL directory
$openssl64 = (Get-ChildItem -Path ${env:ProgramFiles} -Directory -Filter "OpenSSL*")[0]
Move-Item -Path $openssl64.FullName -Destination "C:\$($openssl64.Name)" -Force
Write-Host "Moved 64-bit OpenSSL to C:\$($openssl64.Name)"
# -----------------------------------------------------------------------------------------------------------------


Write-Host "Installing OpenSSL 3.0.18 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_0_18.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_0_18.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v30-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v30-Win32-temp -Destination C:\OpenSSL-v30-Win32 -Recurse

Write-Host "Installing OpenSSL 3.0.18 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_0_18.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_0_18.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v30-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v30-Win64-temp -Destination C:\OpenSSL-v30-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.0.18 (32-bit)"
UninstallOpenSSL "OpenSSL 3.0.18 (64-bit)"


Write-Host "Installing OpenSSL 3.2.6 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_2_6.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_2_6.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v32-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v32-Win32-temp -Destination C:\OpenSSL-v32-Win32 -Recurse

Write-Host "Installing OpenSSL 3.2.6 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_2_6.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_2_6.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v32-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v32-Win64-temp -Destination C:\OpenSSL-v32-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.2.6 (32-bit)"
UninstallOpenSSL "OpenSSL 3.2.6 (64-bit)"


Write-Host "Installing OpenSSL 3.3.5 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-3_3_5.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win32OpenSSL-3_3_5.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v33-Win32-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v33-Win32-temp -Destination C:\OpenSSL-v33-Win32 -Recurse

Write-Host "Installing OpenSSL 3.3.5 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-3_3_5.exe"
(New-Object Net.WebClient).DownloadFile("https://slproweb.com/download/Win64OpenSSL-3_3_5.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes /DIR=C:\OpenSSL-v33-Win64-temp
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
Copy-Item C:\OpenSSL-v33-Win64-temp -Destination C:\OpenSSL-v33-Win64 -Recurse

UninstallOpenSSL "OpenSSL 3.3.5 (32-bit)"
UninstallOpenSSL "OpenSSL 3.3.5 (64-bit)"

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
