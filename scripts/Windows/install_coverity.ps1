Write-Host "Installing Coverity 2019.03..." -ForegroundColor Cyan
$destPath = "$env:SYSTEMDRIVE\Tools\Coverity"
if (Test-Path $destPath ) {
  echo "Deleting $($destPath)..."
  del $destPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\cov-analysis-win64-2019.03.zip"
(New-Object Net.WebClient).DownloadFile('https://storage.googleapis.com/appveyor-download-cache/coverity/cov-analysis-win64-2019.03.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\Coverity"
7z x $zipPath -o"$tempPath" | Out-Null

[IO.Directory]::Move("$tempPath\cov-analysis-win64-2019.03", $destPath)
del $tempPath -Recurse -Force
del $zipPath

Add-Path "$destPath\bin"

Write-Host "Installed" -ForegroundColor Green