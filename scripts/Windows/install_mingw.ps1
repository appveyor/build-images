Write-Host "Installing MinGW..." -ForegroundColor Cyan

$mingwPath = "C:\MinGW"

if(Test-Path $mingwPath) {
    Write-Host "Removing existing MinGW installation..."
    Remove-Item $mingwPath -Recurse -Force
}

# download installer
$zipPath = "$env:TEMP\mingw-get-0.6.3-mingw32-pre-20170905-1-bin.zip"
Write-Host "Downloading..."
#(New-Object Net.WebClient).DownloadFile('https://osdn.net/frs/redir.php?m=plug&f=mingw%2F68260%2Fmingw-get-0.6.3-mingw32-pre-20170905-1-bin.zip', $zipPath)
Invoke-WebRequest -Uri 'https://osdn.net/frs/redir.php?m=plug&f=mingw%2F68260%2Fmingw-get-0.6.3-mingw32-pre-20170905-1-bin.zip' -OutFile $zipPath -SkipCertificateCheck
#(New-Object Net.WebClient).DownloadFile('https://osdn.net/projects/mingw/downloads/68260/mingw-get-0.6.3-mingw32-pre-20170905-1-bin.zip', $zipPath)
Push-Location -Path $zipPath
Write-Host "Unzipping..."
7z x $zipPath -y -o"$mingwPath" | Out-Null
Remove-Item $zipPath

# install MinGW
$logsDir = "$env:TEMP\mingw-install-logs"
New-Item $logsDir -ItemType Directory -Force | Out-Null

function InstallPackage($packageName) {
    Write-Host "Installing package $packageName..." -NoNewline
    C:\MinGW\bin\mingw-get install $packageName 1> "$logsDir\$packageName.log" 2>&1
    Write-Host "OK"
}

InstallPackage mingw-get
InstallPackage mingw-developer-toolkit
InstallPackage mingw32-base
InstallPackage mingw32-make
InstallPackage msys-base
InstallPackage gcc
InstallPackage g++
InstallPackage msys-rxvt
InstallPackage msys-unzip
InstallPackage msys-wget
InstallPackage msys-zip

Write-Host "Installed MinGW" -ForegroundColor Green

Write-Host "Compacting C:\MinGW..." -ForegroundColor Cyan -NoNewline
compact /c /s:C:\MinGW | Out-Null
Write-Host "OK"