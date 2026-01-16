. "$PSScriptRoot\common.ps1"

# installers at https://repo.anaconda.com/miniconda/

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSVersionTable
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Mobile; rv:18.0) Gecko/18.0 Firefox/18.0"
}

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

Remove-Item C:\Miniconda3 -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item C:\Miniconda3-x64 -Force -Recurse -ErrorAction SilentlyContinue
#25.11.1

Write-Host "Installing Miniconda3 25.11.1 (Python 3.13 64-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-25.11.1-Windows-x86_64.exe"
Invoke-WebRequest -Uri "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe" -outfile $exePath -Headers $headers
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda-x64
Remove-Item $exePath

Write-Host "Installing Miniconda3 25.11.1 (Python 3.13 32-bit)..." -ForegroundColor Cyan
Write-Host "Downloading..."
$exePath = "$env:TEMP\Miniconda3-25.11.1-Windows-x86.exe"
Invoke-WebRequest -Uri "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86.exe" -outfile $exePath -Headers $headers
Write-Host "Installing..."
cmd /c start /wait $exePath /InstallationType=AllUsers /RegisterPython=0 /AddToPath=0 /S /D=C:\Miniconda
Remove-Item $exePath





function CheckMiniconda($path) {
    if (-not (Test-Path "$path\python.exe")) { throw "python.exe is missing in $path"; }
    elseif (-not (Test-Path "$path\Scripts\conda.exe")) { throw "conda.exe is missing in $path"; }
    else { Write-Host "$path is OK" -ForegroundColor Green; }

    Start-ProcessWithOutput "$path\python --version"
    Start-ProcessWithOutput "$path\Scripts\conda --version"
}

CheckMiniconda 'C:\Miniconda'
CheckMiniconda 'C:\Miniconda-x64'
