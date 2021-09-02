if (-not ((test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community") -or
    (test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community") -or
    (test-path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview")))
{
    Write-Host "Service Fabric requires VS 2017 or VS 2019" -ForegroundColor Yellow
    return
}

Write-Host "Installing Service Fabric 7.0" -ForegroundColor Cyan

# install runtime
Write-Host "Downloading Service Fabric Runtime..."
$exePath = "$env:TEMP\MicrosoftServiceFabricRuntime.exe"
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/MicrosoftServiceFabric.7.0.470.9590.exe', $exePath)

Write-Host "Installing Service Fabric Runtime..."
cmd /c start /wait $exePath /AcceptEULA
Remove-Item $exePath

Write-Host "Installing Service Fabric SDK..."

Write-Host "Downloading..."
$msiPath = "$env:TEMP\MicrosoftServiceFabricSDK.msi"
(New-Object Net.WebClient).DownloadFile('https://appveyordownloads.blob.core.windows.net/misc/MicrosoftServiceFabricSDK.4.0.470.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i "$msiPath" /quiet
Remove-Item $msiPath

Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Service Fabric Local Cluster Manager.lnk" -Force

Write-Host "Service Fabric installed" -ForegroundColor Green
