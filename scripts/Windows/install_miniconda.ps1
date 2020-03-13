. "$PSScriptRoot\common.ps1"

# http://repo.continuum.io/miniconda/

function UninstallMiniconda($condaName) {
    $regPath = $null
    $uninstallString = $null

    if(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    } elseif (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    } elseif (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName") {
        $uninstallString = $((Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName").QuietUninstallString)
        $regPath = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$condaName"
    }

    if($uninstallString) {
        Write-Host "Uninstalling $condaName"
        $uninstallString | out-file "$env:temp\uninstall.cmd" -Encoding ASCII
        & "$env:temp\uninstall.cmd"
        Remove-Item "$env:temp\uninstall.cmd"
        Remove-Item $regPath
    } else {
        Write-Host "$condaName is not installed"
    }
}

UninstallMiniconda "Python 2.7.15 (Miniconda2 4.5.11 32-bit)"
UninstallMiniconda "Python 2.7.15 (Miniconda2 4.5.11 64-bit)"

UninstallMiniconda "Miniconda2 4.7.12 (Python 2.7.16 32-bit)"
UninstallMiniconda "Miniconda2 4.7.12 (Python 2.7.16 64-bit)"

UninstallMiniconda "Python 3.4.3 (Miniconda3 3.16.0 32-bit)"
UninstallMiniconda "Python 3.4.3 (Miniconda3 3.16.0 64-bit)"

UninstallMiniconda "Python 3.5.2 (Miniconda3 4.2.12 32-bit)"
UninstallMiniconda "Python 3.5.2 (Miniconda3 4.2.12 64-bit)"

UninstallMiniconda "Python 3.6.5 (Miniconda3 4.5.4 32-bit)"
UninstallMiniconda "Python 3.6.5 (Miniconda3 4.5.4 64-bit)"

UninstallMiniconda "Python 3.7.0 (Miniconda3 4.5.11 32-bit)"
UninstallMiniconda "Python 3.7.0 (Miniconda3 4.5.11 64-bit)"

UninstallMiniconda "Miniconda3 4.7.12 (Python 3.7.4 32-bit)"
UninstallMiniconda "Miniconda3 4.7.12 (Python 3.7.4 64-bit)"

Start-Sleep -Seconds 30

Remove-Item C:\Miniconda3 -Force -Recurse
Remove-Item C:\Miniconda3-x64 -Force -Recurse

Write-Host "Installing Miniconda2 4.7.12 (Python 2.7.16 64-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda2-4.7.12.1-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda-x64
Remove-Item $exePath

Write-Host "Installing Miniconda2 4.7.12 (Python 2.7.16 32-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda2-4.7.12.1-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda
Remove-Item $exePath



Write-Host "Installing Miniconda3 3.16.0 Python 3.4.3 x64..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-3.16.0-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-3.16.0-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda34-x64
Remove-Item $exePath

Write-Host "Installing Miniconda3 3.16.0 Python 3.4.3 x86..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-3.16.0-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-3.16.0-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda34
Remove-Item $exePath



Write-Host "Installing Miniconda3 4.2.12 Python 3.5.2 x64..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-4.2.12-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda35-x64
Remove-Item $exePath

Write-Host "Installing Miniconda3 4.2.12 Python 3.5.2 x86..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-4.2.12-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda35
Remove-Item $exePath



Write-Host "Installing Miniconda3 4.5.4 Python 3.6.5 x64..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-4.5.4-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-4.5.4-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda36-x64
Remove-Item $exePath

Write-Host "Installing Miniconda3 4.5.4 Python 3.6.5 x86..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-4.5.4-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-4.5.4-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda36
Remove-Item $exePath



Write-Host "Installing Miniconda3 4.8.2 (Python 3.7.6 64-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-py37_4.8.2-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-py37_4.8.2-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda37-x64
Remove-Item $exePath

Write-Host "Installing Miniconda3 4.8.2 (Python 3.7.6 32-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-py37_4.8.2-Windows-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-py37_4.8.2-Windows-x86.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda37
Remove-Item $exePath



Write-Host "Installing Miniconda3 4.8.2 (Python 3.8.1 64-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-py38_4.8.2-Windows-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://repo.continuum.io/miniconda/Miniconda3-py38_4.8.2-Windows-x86_64.exe', $exePath)
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda38-x64
Remove-Item $exePath


cmd /c mklink /J C:\Miniconda3 C:\Miniconda37
cmd /c mklink /J C:\Miniconda3-x64 C:\Miniconda37-x64


function CheckMiniconda($path) {
    if (-not (Test-Path "$path\python.exe")) { throw "python.exe is missing in $path"; }
    elseif (-not (Test-Path "$path\Scripts\conda.exe")) { throw "conda.exe is missing in $path"; }
    else { Write-Host "$path is OK" -ForegroundColor Green; }

    Start-ProcessWithOutput "$path\python --version"
    Start-ProcessWithOutput "$path\Scripts\conda --version"
}

CheckMiniconda 'C:\Miniconda'
CheckMiniconda 'C:\Miniconda-x64'

CheckMiniconda 'C:\Miniconda3'
CheckMiniconda 'C:\Miniconda3-x64'

CheckMiniconda 'C:\Miniconda34'
CheckMiniconda 'C:\Miniconda34-x64'

CheckMiniconda 'C:\Miniconda35'
CheckMiniconda 'C:\Miniconda35-x64'

CheckMiniconda 'C:\Miniconda36'
CheckMiniconda 'C:\Miniconda36-x64'

CheckMiniconda 'C:\Miniconda37'
CheckMiniconda 'C:\Miniconda37-x64'

CheckMiniconda 'C:\Miniconda38-x64'