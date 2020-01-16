Write-Host "Installing Git 2.25.0"
Write-Host "====================="

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$exePath = "$env:TEMP\Git-install.exe"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.25.0.windows.1/Git-2.25.0-64-bit.exe', $exePath)

Write-Host "Installing..."
cmd /c start /wait $exePath /VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS="icons,icons\quicklaunch,ext,ext\reg,ext\reg\shellhere,ext\reg\guihere,assoc,assoc_sh" /LOG
del $exePath

$gitCmdPath = "$env:ProgramFiles\Git\cmd"
Remove-Path $gitCmdPath
Add-Path $gitCmdPath -before
Add-SessionPath $gitCmdPath

$gitUsrBinPath = "$env:ProgramFiles\Git\usr\bin"
Remove-Path $gitUsrBinPath
Add-Path $gitUsrBinPath
Add-SessionPath $gitUsrBinPath

git config --global core.autocrlf input
git config --system --unset credential.helper
git --version

Write-Host "Git installed" -ForegroundColor Green

# CHECK!!!!!
# git config --list

<#
Git config files locations:
- C:\Program Files\Git\mingw64\etc\gitconfig
- %programdata%\git\config
- %userprofile%\.gitconfig
C:\Users\appveyor>git config --list
core.symlinks=false
core.autocrlf=true
core.fscache=true
color.diff=auto
color.status=auto
color.branch=auto
color.interactive=true
help.format=html
diff.astextplain.textconv=astextplain
rebase.autosquash=true
http.sslcainfo=C:/Program Files/Git/mingw64/ssl/certs/ca-bundle.crt
diff.astextplain.textconv=astextplain
core.autocrlf=input
filter.lfs.required=true
filter.lfs.clean=git-lfs clean -- %f
filter.lfs.smudge=git-lfs smudge -- %f
filter.lfs.process=git-lfs filter-process
#>