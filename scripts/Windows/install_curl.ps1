# Downloaded from: https://bintray.com/vszakats/generic/curl/7.55.1

Write-Host "Installing curl..." -ForegroundColor Cyan

$destPath = 'C:\Tools\curl'

if(Test-Path $destPath) {
    Remove-Item $destPath -Recurse -Force
}

$zipPath = "$env:TEMP\curl-7.55.1-win64-mingw.7z"
$tempPath = "$env:TEMP\curl"
(New-Object Net.WebClient).DownloadFile('https://bintray.com/vszakats/generic/download_file?file_path=curl-7.55.1-win64-mingw.7z', $zipPath)
7z x $zipPath -aoa -o"$tempPath"
[IO.Directory]::Move("$tempPath\curl-7.55.1-win64-mingw", $destPath)

del $zipPath
Remove-Item $tempPath -Recurse -Force

Add-Path "$destPath\bin"

Write-Host "Installed curl" -ForegroundColor Green
