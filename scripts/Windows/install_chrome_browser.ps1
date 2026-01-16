. "$PSScriptRoot\common.ps1"
#143.0.7499.192
Write-Host "Installing Chrome..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\googlechromestandaloneenterprise64.msi"
#(New-Object Net.WebClient).DownloadFile('https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi', $msiPath)
(New-Object Net.WebClient).DownloadFile('https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B5CD65CD9-C1D0-4A31-AEAA-4DFABF623BF5%7D%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26ap%3Dx64-stable-statsdef_0%26brand%3DGCEA/dl/chrome/install/googlechromestandaloneenterprise64.msi', $msiPath)

Remove-Item $msiPath

Set-Service gupdate -StartupType Manual -ErrorAction SilentlyContinue
Set-Service gupdatem -StartupType Manual -ErrorAction SilentlyContinue

Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineCore -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName GoogleUpdateTaskMachineUA -Confirm:$false -ErrorAction SilentlyContinue

Start-Sleep -s 5
GetProductVersion "Chrome"

Write-Host "Installed Chrome" -ForegroundColor Green