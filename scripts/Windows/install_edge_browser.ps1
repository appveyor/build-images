Write-Host "Installing Microsoft Edge..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftEdgeEnterpriseX64.msi"
(New-Object Net.WebClient).DownloadFile('http://dl.delivery.mp.microsoft.com/filestreamingservice/files/c39f1d27-cd11-495a-b638-eac3775b469d/MicrosoftEdgeEnterpriseX64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /qn /norestart
Remove-Item $msiPath

# command-line options for testing: https://help.appveyor.com/discussions/questions/45894-can-we-include-microsoft-edge-browser#comment_48015293

# "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --no-first-run --noerrdialogs --no-default-browser-check  --start-maximized

Write-Host "Installed Microsoft Edge" -ForegroundColor Green