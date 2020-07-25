# https://www.doxygen.nl/download.html

Write-Host "Installing Graphviz..." -ForegroundColor Cyan

$destPath = 'C:\Tools\Graphviz'

if(-not (Test-Path $destPath)) {
    New-Item $destPath -ItemType directory -Force | Out-Null
}

Remove-Item $destPath -Force -Recurse

$zipPath = "$env:TEMP\graphviz.zip"
$tempPath = "$env:TEMP\graphviz-temp"
(New-Object Net.WebClient).DownloadFile('https://graphviz.gitlab.io/_pages/Download/windows/graphviz-2.38.zip', $zipPath)
7z x $zipPath -aoa -o"$tempPath"
[IO.Directory]::Move("$tempPath\release", $destPath)
Remove-Item $zipPath
Remove-Item $tempPath -Recurse -Force

Add-Path "$destPath\bin"

Write-Host "Installed Graphviz" -ForegroundColor Green