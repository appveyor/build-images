. "$PSScriptRoot\common.ps1"

Write-Host "Installing Microsoft Edge..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftEdgeEnterpriseX64.msi"
(New-Object Net.WebClient).DownloadFile('http://dl.delivery.mp.microsoft.com/filestreamingservice/files/91428d7d-3dcb-4368-8edd-7ab685a40418/MicrosoftEdgeEnterpriseX64.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /qn /norestart
Remove-Item $msiPath

Set-Service edgeupdate -StartupType Manual -ErrorAction SilentlyContinue
Set-Service edgeupdatem -StartupType Manual -ErrorAction SilentlyContinue

Unregister-ScheduledTask -TaskName MicrosoftEdgeUpdateTaskMachineCore -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName MicrosoftEdgeUpdateTaskMachineUA -Confirm:$false -ErrorAction SilentlyContinue

# command-line options for testing: https://help.appveyor.com/discussions/questions/45894-can-we-include-microsoft-edge-browser#comment_48015293

# & "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --no-first-run --noerrdialogs --no-default-browser-check  --start-maximized

GetProductVersion "Edge"

Write-Host "Installed Microsoft Edge" -ForegroundColor Green