
Write-Host "Installing Service Fabric 11.2.274.1" -ForegroundColor Cyan

# install runtime
Write-Host "Downloading Service Fabric Runtime..."
$exePath = "$env:TEMP\MicrosoftServiceFabricRuntime.exe"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/b/8/a/b8a2fb98-0ec1-41e5-be98-9d8b5abf7856/MicrosoftServiceFabric.11.1.274.1.exe', $exePath)

Write-Host "Installing Service Fabric Runtime..."
cmd /c start /wait $exePath /AcceptEULA
Remove-Item $exePath

Write-Host "Installing Service Fabric SDK..."

Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftServiceFabricSDK.msi"
(New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/b/8/a/b8a2fb98-0ec1-41e5-be98-9d8b5abf7856/MicrosoftServiceFabricSDK.8.1.274.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet
Remove-Item $msiPath

Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Service Fabric Local Cluster Manager.lnk" -Force

Write-Host "Service Fabric installed" -ForegroundColor Green
