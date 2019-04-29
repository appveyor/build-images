Write-Host "Installing PsTools"
Write-Host "=================="

$destPath = "$env:SYSTEMDRIVE\Tools\PsTools"
if(Test-Path $destPath) {
    del $destPath -Recurse -Force
}

$zipPath = "$env:TEMP\PSTools.zip"
(New-Object Net.WebClient).DownloadFile('https://download.sysinternals.com/files/PSTools.zip', $zipPath)

7z x $zipPath -o"$destPath" | Out-Null
del $zipPath

Add-Path $destPath
Add-SessionPath $destPath

Write-Host "PsTools installed"