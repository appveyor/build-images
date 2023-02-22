. "$PSScriptRoot\common.ps1"

Write-Host "Installing Cygwin x64..." -ForegroundColor Cyan

if(Test-Path C:\cygwin) {
    Write-Host "Deleting existing installation..."
    Remove-Item C:\cygwin -Recurse -Force
}

# download installer
New-Item -Path C:\cygwin -ItemType Directory -Force
$exePath = "C:\cygwin\setup-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86_64.exe', $exePath)
dir C:\cygwin

# install cygwin
Start-ProcessWithOutput "$exePath -qnNdO -R C:/cygwin -s http://cygwin.mirror.constant.com -l C:/cygwin/var/cache/setup -P mingw64-i686-gcc-g++ -P mingw64-x86_64-gcc-g++ -P gcc-g++ -P autoconf -P automake -P bison -P libtool -P make -P python2 -P python -P python38 -P gettext-devel -P intltool -P libiconv -P pkg-config -P wget -P curl"
C:\Cygwin\bin\bash -lc true

cmd /c "C:\cygwin\bin\cygcheck -c | C:\cygwin\bin\grep cygwin"
cmd /c "C:\cygwin\bin\gcc --version"

Write-Host "Installed Cygwin x64" -ForegroundColor Green

if(Test-Path C:\cygwin64) {
    Write-Host "Deleting C:\cygwin64..."
    Remove-Item C:\cygwin64 -Recurse -Force
}

New-Item -ItemType SymbolicLink -Path "C:\cygwin64" -Target "C:\cygwin" -Force | Out-Null
dir C:\cygwin64

# compact folders
Write-Host "Compacting C:\cygwin..." -NoNewline
Start-ProcessWithOutput "compact /c /i /q /s:C:\cygwin" -IgnoreStdOut
Write-Host "OK" -ForegroundColor Green