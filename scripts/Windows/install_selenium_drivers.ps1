# The list of all available drivers:
# http://chromedriver.storage.googleapis.com/index.html

Write-Host "Installing Chrome Selenium driver..." -ForegroundColor Cyan

$destPath = 'C:\Tools\WebDriver'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:TEMP\chromedriver_win32.zip"
(New-Object Net.WebClient).DownloadFile('http://chromedriver.storage.googleapis.com/79.0.3945.36/chromedriver_win32.zip', $zipPath)
7z x $zipPath -aoa -o"$destPath"
del $zipPath

Add-Path $destPath

Write-Host "Installed Chrome Selenium driver" -ForegroundColor Green






Write-Host "Installing FireFox Selenium driver..." -ForegroundColor Cyan

# https://github.com/mozilla/geckodriver/releases

$destPath = 'C:\Tools\WebDriver'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:USERPROFILE\geckodriver-v0.26.0-win32.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-win32.zip', $zipPath)
7z x $zipPath -o"$destPath" -aoa
del $zipPath

copy "$destPath\geckodriver.exe" "$destPath\wires.exe"

Add-Path $destPath

Write-Host "Installed FireFox Selenium driver" -ForegroundColor Green





# All versions:
# 
# http://selenium-release.storage.googleapis.com/index.html
#
Write-Host "Installing IE Selenium driver..." -ForegroundColor Cyan

$destPath = 'C:\Tools\WebDriver'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

$zipPath = "$env:TEMP\IEDriverServer_Win32_3.150.1.zip"
(New-Object Net.WebClient).DownloadFile('http://selenium-release.storage.googleapis.com/3.150/IEDriverServer_Win32_3.150.1.zip', $zipPath)
7z x $zipPath -o"$destPath" -aoa
del $zipPath

Add-Path $destPath

# enable protected mode for all IE security zones
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4' -Name "2500" -Value 0

Write-Host "Installed IE Selenium driver" -ForegroundColor Green
