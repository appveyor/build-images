﻿$destPath = 'C:\Tools\WebDriver'

if (-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}
else {
    Get-ChildItem "$destPath\*" -Recurse | Remove-Item -Recurse
}

Add-Path $destPath

# The list of all available drivers:
# http://chromedriver.storage.googleapis.com/index.html

Write-Host "Installing Chrome Selenium driver..." -ForegroundColor Cyan

$zipPath = "$env:TEMP\chromedriver_win32.zip"
(New-Object Net.WebClient).DownloadFile('https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/116.0.5845.96/win32/chromedriver-win32.zip', $zipPath)
7z e $zipPath -spe -o"$destPath"
Remove-Item $zipPath

Write-Host "Installed Chrome Selenium driver" -ForegroundColor Green



# The list of all available drivers:
# https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/

Write-Host "Installing Edge Selenium driver..." -ForegroundColor Cyan

$zipPath = "$env:TEMP\edgedriver_win32.zip"
(New-Object Net.WebClient).DownloadFile('https://msedgedriver.azureedge.net/116.0.1938.62/edgedriver_win32.zip', $zipPath)
7z x $zipPath -aoa -o"$destPath"
Remove-Item $zipPath

Write-Host "Installed Edge Selenium driver" -ForegroundColor Green




Write-Host "Installing FireFox Selenium driver..." -ForegroundColor Cyan

# https://github.com/mozilla/geckodriver/releases

$zipPath = "$env:TEMP\geckodriver-v0.33.0-win32.zip"
(New-Object Net.WebClient).DownloadFile('https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-win32.zip', $zipPath)
7z x $zipPath -o"$destPath" -aoa
Remove-Item $zipPath

Copy-Item "$destPath\geckodriver.exe" "$destPath\wires.exe"

Write-Host "Installed FireFox Selenium driver" -ForegroundColor Green





# All versions:
# 
# http://selenium-release.storage.googleapis.com/index.html
#
Write-Host "Installing IE Selenium driver..." -ForegroundColor Cyan

$zipPath = "$env:TEMP\IEDriverServer_Win32_3.150.1.zip"
(New-Object Net.WebClient).DownloadFile('http://selenium-release.storage.googleapis.com/3.150/IEDriverServer_Win32_3.150.1.zip', $zipPath)
7z x $zipPath -o"$destPath" -aoa
Remove-Item $zipPath

# enable protected mode for all IE security zones
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3' -Name "2500" -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4' -Name "2500" -Value 0

Write-Host "Installed IE Selenium driver" -ForegroundColor Green