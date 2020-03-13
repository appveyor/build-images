Write-Host "Installing Service Fabric 7.0" -ForegroundColor Cyan

# install runtime
Write-Host "Downloading Service Fabric Runtime..."
$exePath = "$env:TEMP\MicrosoftServiceFabricRuntime.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/0/0/f/00fbca28-0a64-4c9a-a3a3-b11763ee17e5/MicrosoftServiceFabric.7.0.470.9590.exe', $exePath)

Write-Host "Installing Service Fabric Runtime..."
cmd /c start /wait $exePath /AcceptEULA
Remove-Item $exePath

# install SDK and VS Tools
if ((test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community") -or
        (test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community")) {
    # SDK only
    Write-Host "Installing Service Fabric SDK..."
    cmd /c start /wait webpicmd /Install /Products:MicrosoftAzure-ServiceFabric-CoreSDK /AcceptEula
} else {
    # SDK and Tools
    Write-Host "Installing Service Fabric SDK and Tools..."
    cmd /c start /wait webpicmd /Install /Products:MicrosoftAzure-ServiceFabric-VS2015 /AcceptEula
}

Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Service Fabric Local Cluster Manager.lnk" -Force

Write-Host "Service Fabric installed" -ForegroundColor Green
