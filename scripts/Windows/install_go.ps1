################################################################################
#
#                   GO 1.12.3
#
################################################################################

Write-Host "Installing Go 1.12.3 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.12.x..."
if(Test-Path 'C:\go112') {
    Remove-Item 'C:\go112' -Recurse -Force
}
if(Test-Path 'C:\go112-x86') {
    Remove-Item 'C:\go112-x86' -Recurse -Force
}

if(Test-Path 'C:\go') {
    Remove-Item 'C:\go' -Recurse -Force
}
if(Test-Path 'C:\go-x86') {
    Remove-Item 'C:\go-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.12.3.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.12.3.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1120-x86 | Out-Null
[IO.Directory]::Move('C:\go1120-x86\go', 'C:\go112-x86')
Remove-Item 'C:\go1120-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.12.3 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.12.3.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.12.3.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1120-x64 | Out-Null
[IO.Directory]::Move('C:\go1120-x64\go', 'C:\go112')
Remove-Item 'C:\go1120-x64' -Recurse -Force
del $goDistPath

################################################################################
#
#                   GO 1.11.8
#
################################################################################

Write-Host "Installing Go 1.11.8 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.11.x..."
if(Test-Path 'C:\go111') {
    Remove-Item 'C:\go111' -Recurse -Force
}
if(Test-Path 'C:\go111-x86') {
    Remove-Item 'C:\go111-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.11.8.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.11.8.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1110-x86 | Out-Null
[IO.Directory]::Move('C:\go1110-x86\go', 'C:\go111-x86')
Remove-Item 'C:\go1110-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.11.8 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.11.8.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.11.8.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1110-x64 | Out-Null
[IO.Directory]::Move('C:\go1110-x64\go', 'C:\go111')
Remove-Item 'C:\go1110-x64' -Recurse -Force
del $goDistPath

################################################################################
#
#                   GO 1.10.8
#
################################################################################

Write-Host "Installing Go 1.10.8 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.10.x..."
if(Test-Path 'C:\go110') {
    Remove-Item 'C:\go110' -Recurse -Force
}
if(Test-Path 'C:\go110-x86') {
    Remove-Item 'C:\go110-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.10.8.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.10.8.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1100-x86 | Out-Null
[IO.Directory]::Move('C:\go1100-x86\go', 'C:\go110-x86')
Remove-Item 'C:\go1100-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.10.8 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.10.8.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.10.8.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go1100-x64 | Out-Null
[IO.Directory]::Move('C:\go1100-x64\go', 'C:\go110')
Remove-Item 'C:\go1100-x64' -Recurse -Force
del $goDistPath

################################################################################
#
#                   GO 1.9.7
#
################################################################################

Write-Host "Installing Go 1.9.7 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.9.x..."
if(Test-Path 'C:\go19') {
    Remove-Item 'C:\go19' -Recurse -Force
}
if(Test-Path 'C:\go19-x86') {
    Remove-Item 'C:\go19-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.9.7.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.9.7.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go194-x86 | Out-Null
[IO.Directory]::Move('C:\go194-x86\go', 'C:\go19-x86')
Remove-Item 'C:\go194-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.9.7 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.9.7.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.9.7.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go194-x64 | Out-Null
[IO.Directory]::Move('C:\go194-x64\go', 'C:\go19')
Remove-Item 'C:\go194-x64' -Recurse -Force
del $goDistPath

################################################################################
#
#                   GO 1.8.7
#
################################################################################

Write-Host "Installing Go 1.8.7 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.8.x..."
if(Test-Path 'C:\go18') {
    Remove-Item 'C:\go18' -Recurse -Force
}
if(Test-Path 'C:\go18-x86') {
    Remove-Item 'C:\go18-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.8.7.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.8.7.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go187-x86 | Out-Null
[IO.Directory]::Move('C:\go187-x86\go', 'C:\go18-x86')
Remove-Item 'C:\go187-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.8.7 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.8.7.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.8.7.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go187-x64 | Out-Null
[IO.Directory]::Move('C:\go187-x64\go', 'C:\go18')
Remove-Item 'C:\go187-x64' -Recurse -Force
del $goDistPath


################################################################################
#
#                   GO 1.7.6
#
################################################################################

Write-Host "Installing Go 1.7.6 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.7.x..."
if(Test-Path 'C:\go17') {
    Remove-Item 'C:\go17' -Recurse -Force
}
if(Test-Path 'C:\go17-x86') {
    Remove-Item 'C:\go17-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.7.6.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.7.6.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go176-x86 | Out-Null
[IO.Directory]::Move('C:\go176-x86\go', 'C:\go17-x86')
Remove-Item 'C:\go176-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.7.6 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.7.6.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.7.6.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go176-x64 | Out-Null
[IO.Directory]::Move('C:\go176-x64\go', 'C:\go17')
Remove-Item 'C:\go176-x64' -Recurse -Force
del $goDistPath


################################################################################
#
#                   GO 1.6.4
#
################################################################################

Write-Host "Installing Go 1.6.4 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.6.x..."
if(Test-Path 'C:\go16') {
    Remove-Item 'C:\go16' -Recurse -Force
}
if(Test-Path 'C:\go16-x86') {
    Remove-Item 'C:\go16-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.6.4.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.6.4.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go164-x86 | Out-Null
[IO.Directory]::Move('C:\go164-x86\go', 'C:\go16-x86')
Remove-Item 'C:\go164-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.6.4 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.6.4.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.6.4.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go164-x64 | Out-Null
[IO.Directory]::Move('C:\go164-x64\go', 'C:\go16')
Remove-Item 'C:\go164-x64' -Recurse -Force
del $goDistPath


################################################################################
#
#                   GO 1.5.4
#
################################################################################


Write-Host "Installing Go 1.5.4 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.5..."
if(Test-Path 'C:\go15') {
    Remove-Item 'C:\go15' -Recurse -Force
}
if(Test-Path 'C:\go15-x86') {
    Remove-Item 'C:\go15-x86' -Recurse -Force
}

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.5.4.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.5.4.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go154-x86 | Out-Null
[IO.Directory]::Move('C:\go154-x86\go', 'C:\go15-x86')
Remove-Item 'C:\go154-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.5.4 x64..." -ForegroundColor Cyan

Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.5.4.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.5.4.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go154-x64 | Out-Null
[IO.Directory]::Move('C:\go154-x64\go', 'C:\go15')
Remove-Item 'C:\go154-x64' -Recurse -Force
del $goDistPath


################################################################################
#
#                   GO 1.4.3
#
################################################################################


Write-Host "Installing Go 1.4.3 x86..." -ForegroundColor Cyan

Write-Host "Removing Go 1.4..."
if(Test-Path 'C:\go14') {
    Remove-Item 'C:\go14' -Recurse -Force
}
if(Test-Path 'C:\go14-x86') {
    Remove-Item 'C:\go14-x86' -Recurse -Force
}

# install Go 1.4.3 x86
Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.4.3.windows-386.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.4.3.windows-386.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go143-x86 | Out-Null
[IO.Directory]::Move('C:\go143-x86\go', 'C:\go14-x86')
Remove-Item 'C:\go143-x86' -Recurse -Force
del $goDistPath

Write-Host "Installing Go 1.4.3 x64..." -ForegroundColor Cyan

# install Go 1.4.3 x64
Write-Host "Downloading..."
$goDistPath = "$env:TEMP\go1.4.3.windows-amd64.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/golang/go1.4.3.windows-amd64.zip', $goDistPath)

Write-Host "Unpacking..."
7z x $goDistPath -oC:\go143-x64 | Out-Null
[IO.Directory]::Move('C:\go143-x64\go', 'C:\go14')
Remove-Item 'C:\go143-x64' -Recurse -Force
del $goDistPath

# make sure paths added
Add-Path C:\go\bin
Add-SessionPath C:\go\bin

# set GOROOT variable
[Environment]::SetEnvironmentVariable("GOROOT", 'C:\go', "Machine")

cmd /c mklink /J C:\go C:\go112
cmd /c mklink /J C:\go-x86 C:\go112-x86

go version

C:\go\bin\go.exe version
C:\go-x86\bin\go.exe version
C:\go14\bin\go.exe version
C:\go14-x86\bin\go.exe version
C:\go15\bin\go.exe version
C:\go15-x86\bin\go.exe version
C:\go16\bin\go.exe version
C:\go16-x86\bin\go.exe version
C:\go17\bin\go.exe version
C:\go17-x86\bin\go.exe version
C:\go18\bin\go.exe version
C:\go18-x86\bin\go.exe version
C:\go19\bin\go.exe version
C:\go19-x86\bin\go.exe version
C:\go110\bin\go.exe version
C:\go110-x86\bin\go.exe version
C:\go111\bin\go.exe version
C:\go111-x86\bin\go.exe version
C:\go112\bin\go.exe version
C:\go112-x86\bin\go.exe version