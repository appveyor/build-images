Write-Host "Installing Azure Service Fabric 2.4.164 for VS 2015 ..." -ForegroundColor Cyan
cmd /c start /wait webpicmd /Install /Products:"MicrosoftAzure-ServiceFabric-VS2015" /AcceptEula
Write-Host "Installed" -ForegroundColor Green