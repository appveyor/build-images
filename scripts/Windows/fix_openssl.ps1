$110Letter = "L"
$111Letter = "u"
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
UninstallOpenSSL "OpenSSL 3.1.1 (32-bit)"
UninstallOpenSSL "OpenSSL 3.1.1 (64-bit)"

# -----------------------------------------------------------------------------------------------------------------

Write-Host "Installing OpenSSL 1.0.2$102Letter 32-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win32OpenSSL-1_0_2$102Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/misc/Win32OpenSSL-1_0_2u.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green

Write-Host "Installing OpenSSL 1.0.2$102Letter 64-bit ..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:temp\Win64OpenSSL-1_0_2$102Letter.exe"
(New-Object Net.WebClient).DownloadFile("https://appveyordownloads.blob.core.windows.net/misc/Win64OpenSSL-1_0_2u.exe", $exePath)
if (-not (Test-Path $exePath)) { throw "Unable to find $exePath" }
Write-Host "Installing..."
cmd /c start /wait $exePath /silent /verysilent /sp- /suppressmsgboxes
Remove-Item $exePath
Write-Host "Installed" -ForegroundColor Green
