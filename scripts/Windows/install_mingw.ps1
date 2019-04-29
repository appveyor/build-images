Write-Host "Installing MinGW..." -ForegroundColor Cyan

$mingwPath = "C:\MinGW"

if(Test-Path $mingwPath) {
    Write-Host "Removing existing MinGW installation..."
    Remove-Item $mingwPath -Recurse -Force
}

# download installer
$zipPath = "$($env:TEMP)\mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar.xz"
$tarPath = "$($env:TEMP)\mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar"
Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('http://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.tar.xz/download', $zipPath)

Write-Host "Untaring..."
7z x $zipPath -y -o"$env:TEMP" | Out-Null

Write-Host "Unzipping..."
7z x $tarPath -y -o"$mingwPath" | Out-Null
del $zipPath
del $tarPath

# install MinGW

$log = "C:\users\appveyor\downloads\install-log.txt"

function InstallPackage($packageName) {
    Write-Host "Installing package $packageName..." -NoNewline
    C:\MinGW\bin\mingw-get install $packageName 1> $log 2>&1
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

del "C:\Windows\System32\install-log.txt"

Write-Host "Installed MinGW" -ForegroundColor Green

Write-Host "Compacting C:\MinGW..." -ForegroundColor Cyan -NoNewline
compact /c /s:C:\MinGW | Out-Null
Write-Host "OK"