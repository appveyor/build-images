Write-Host "Installing Coverity 2024.12.1..." -ForegroundColor Cyan
$destPath = "$env:SYSTEMDRIVE\Tools\Coverity"
if (Test-Path $destPath ) {
  echo "Deleting $($destPath)..."
  del $destPath -Recurse -Force
}

Write-Host "Downloading..."
$zipPath = "$env:TEMP\cov-analysis-win64-2024.12.1.zip"
#(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/cov-analysis-win64-2023.12.2.zip', $zipPath)
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/cov-analysis-win64-2024.12.1.zip', $zipPath)

Write-Host "Unpacking..."
$tempPath = "$env:TEMP\Coverity"
7z x $zipPath -o"$tempPath" -y | Out-Null

Write-Host "Moving..."
[IO.Directory]::Move("$tempPath\cov-analysis-win64-2024.12.1", $destPath)
del $tempPath -Recurse -Force
del $zipPath

Add-Path "$destPath\bin"

Write-Host "Installed" -ForegroundColor Green