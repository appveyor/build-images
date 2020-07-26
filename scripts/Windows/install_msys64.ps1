Write-Host "Installing MSYS2..." -ForegroundColor Cyan

if(Test-path C:\msys64) {
    Remove-Item C:\msys64 -Recurse -Force
}

# download installer
$zipPath = "$($env:TEMP)\msys2-x86_64-latest.tar.xz"
$tarPath = "$($env:TEMP)\msys2-x86_64-latest.tar"
Write-Host "Downloading MSYS installation package..."
(New-Object Net.WebClient).DownloadFile('http://repo.msys2.org/distrib/msys2-x86_64-latest.tar.xz', $zipPath)

Write-Host "Untaring installation package..."
7z x $zipPath -y -o"$env:TEMP" | Out-Null

Write-Host "Unzipping installation package..."
7z x $tarPath -y -oC:\ | Out-Null
Remove-Item $zipPath
Remove-Item $tarPath

function bash($command) {
    Write-Host $command -NoNewline
    cmd /c start /wait C:\msys64\usr\bin\sh.exe --login -c $command
    Write-Host " - OK" -ForegroundColor Green
}

[Environment]::SetEnvironmentVariable("MSYS2_PATH_TYPE", "inherit", "Machine")

# install latest pacman
#bash 'pacman -Sy --noconfirm pacman pacman-mirrors'

# update core packages
bash "pacman -Syuu --noconfirm && ps -ef | grep 'gpg-agent' | grep -v grep | awk '{print `$2}' | xargs -r kill -9"
bash "pacman -Syuu --noconfirm && ps -ef | grep 'gpg-agent' | grep -v grep | awk '{print `$2}' | xargs -r kill -9"

# install packages
bash 'pacman --sync --noconfirm VCS'
bash 'pacman --sync --noconfirm base-devel'
bash 'pacman --sync --noconfirm msys2-devel'
bash 'pacman --sync --noconfirm mingw-w64-{x86_64,i686}-toolchain'

# cleanup pacman cache
Remove-Item c:\msys64\var\cache\pacman\pkg -Recurse -Force

# add mapping for .sh files
cmd /c ftype sh_auto_file="C:\msys64\usr\bin\bash.exe" "`"%L`"" %* | out-null
cmd /c assoc .sh=sh_auto_file

# compact folder
Write-Host "Compacting C:\msys64..." -NoNewline
compact /c /i /s:C:\msys64 | Out-Null
Write-Host "OK" -ForegroundColor Green

Write-Host "MSYS2 installed" -ForegroundColor Green

# testing $PATH
# C:\msys64\usr\bin\sh.exe -lc "echo $PATH"
# C:\msys64\usr\bin\bash.exe -lc "echo $PATH"




#C:\msys64\usr\bin\sh.exe -lc "pacman -Sy --noconfirm pacman pacman-mirrors"
#C:\msys64\usr\bin\sh.exe -lc "pacman -Syu --noconfirm"
#C:\msys64\usr\bin\sh.exe -lc "pacman -Syu --noconfirm"
#C:\msys64\usr\bin\sh.exe -lc "pacman --sync --noconfirm VCS"
#C:\msys64\usr\bin\sh.exe -lc "pacman --sync --noconfirm base-devel"
#C:\msys64\usr\bin\sh.exe -lc "pacman --sync --noconfirm msys2-devel"
#C:\msys64\usr\bin\sh.exe -lc "pacman --sync --noconfirm mingw-w64-{x86_64,i686}-toolchain"