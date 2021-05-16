# Downloaded from: https://curl.se/windows/

Write-Host "Installing curl..." -ForegroundColor Cyan

$destPath = 'C:\Tools\curl'

if(Test-Path $destPath) {
    Remove-Item $destPath -Recurse -Force
}

$zipPath = "$env:TEMP\curl-7.76.1_2-win64-mingw.zip"
$tempPath = "$env:TEMP\curl"
(New-Object Net.WebClient).DownloadFile('https://curl.se/windows/dl-7.76.1_2/curl-7.76.1_2-win64-mingw.zip', $zipPath)
7z x $zipPath -aoa -o"$tempPath"
[IO.Directory]::Move("$tempPath\curl-7.76.1_2-win64-mingw", $destPath)

del $zipPath
Remove-Item $tempPath -Recurse -Force

Add-Path "$destPath\bin"

Write-Host "Installed curl" -ForegroundColor Green
