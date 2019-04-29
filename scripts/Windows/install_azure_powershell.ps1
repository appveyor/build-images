Write-Host "Installing Azure PowerShell ..." -ForegroundColor Cyan

Write-Host "Downloading..."
$msiPath = "$env:TEMP\azure-powershell.5.7.0.msi"
(New-Object Net.WebClient).DownloadFile('https://github.com/Azure/azure-powershell/releases/download/v5.7.0-April2018/azure-powershell.5.7.0.msi', $msiPath)

Write-Host "Installing..."
cmd /c start /wait msiexec /i $msiPath /quiet
del $msiPath

Write-Host "Installed" -ForegroundColor Green

# Disable Azure PowerShell data collection
$azureCollectionProfilePath = "$env:APPDATA\Windows Azure Powershell\AzureDataCollectionProfile.json"
if(-not (Test-Path $azureCollectionProfilePath)) {
    Write-Host "Creating AzureDataCollectionProfile.json"
    New-Item -path "$env:APPDATA\Windows Azure Powershell" -type directory | Out-Null
    Set-Content -path $azureCollectionProfilePath -value '{"enableAzureDataCollection":false}'
} else {
    Write-Host "AzureDataCollectionProfile.json already exists"
}

# test installation
Get-Command Login-AzureRmAccount
Get-Command Get-AzureRmApiManagementBackend
